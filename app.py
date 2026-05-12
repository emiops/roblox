import streamlit as st
import json
import pandas as pd
import zipfile
import io
import os
from sqlalchemy import create_engine, text, inspect, MetaData
from google import genai
from google.genai import types
from langfuse import Langfuse

# --- Page Config & Styling ---
st.set_page_config(page_title="Data Assistant", page_icon="🗄️", layout="wide")

st.markdown("""
<style>
    /* Hide the default Streamlit header and hamburger menu */
    [data-testid="stHeader"] {
        display: none;
    }
    #MainMenu {
        visibility: hidden;
    }

    /* Light grey background for the overall app (Right panel) */
    .stApp, [data-testid="stMain"] {
        background-color: #f3f4f6;
    }
    
    /* Aggressively expand the main content area to fill the screen */
    .block-container, [data-testid="block-container"] {
        max-width: 100% !important;
        width: 100% !important;
        padding-left: 1rem !important;
        padding-right: 1rem !important;
        padding-top: 1rem !important;
        padding-bottom: 1rem !important;
    }
    
    /* Remove padding from the main wrapper to avoid double-margins */
    [data-testid="stMain"] > div:first-child {
        padding: 0 !important;
        max-width: 100% !important;
    }
    
    /* Force Left Panel (Sidebar) to be crisp white */
    [data-testid="stSidebar"] {
        background-color: #ffffff !important;
        border-right: 1px solid #e5e7eb;
    }
    [data-testid="stSidebarHeader"] {
        background-color: #ffffff !important;
    }
    
    /* Make primary buttons dark slate to match mockup */
    .stButton > button[kind="primary"] {
        background-color: #1e293b;
        color: white;
        border: none;
        border-radius: 6px;
        padding: 0.5rem 1rem;
    }
    .stButton > button[kind="primary"]:hover {
        background-color: #334155;
        color: white;
    }
    
    /* Style containers to look like crisp white cards */
    [data-testid="stVerticalBlockBorderWrapper"] {
        background-color: #ffffff;
        border-radius: 8px;
        border: 1px solid #e5e7eb;
        box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
        padding: 1rem;
    }
    
    /* Tweak text inputs and headers for cleaner look */
    label {
        font-weight: 500 !important;
        color: #374151 !important;
    }
    h4 {
        margin-top: 0 !important;
        padding-top: 0 !important;
    }

    /* Match Max Tokens input height with Temperature slider */
    [data-testid="stNumberInput"] {
        padding-bottom: 24px; 
    }

    /* Hide number input step arrows to match mockup exactly */
    input[type="number"]::-webkit-inner-spin-button, 
    input[type="number"]::-webkit-outer-spin-button {
        -webkit-appearance: none;
        margin: 0;
    }
    input[type="number"] {
        -moz-appearance: textfield;
    }
</style>
""", unsafe_allow_html=True)

# --- Initialize Langfuse & GenAI ---
langfuse = Langfuse(
    secret_key="sk-lf-00f72b7b-d0d3-4cde-a030-b70ced717bfa",
    public_key="pk-lf-84c6824e-74d7-4951-98d9-d61be50ddc20",
    host="http://localhost:3000"
)

# Initialize GenAI Client using Application Default Credentials (Vertex AI)
client = genai.Client(vertexai=True, project="gd-gcp-gridu-genai", location="us-central1")

# --- Session State Initialization ---
if 'generated_data' not in st.session_state:
    st.session_state.generated_data = None
if 'active_table' not in st.session_state:
    st.session_state.active_table = None
if 'chat_history' not in st.session_state:
    st.session_state.chat_history = []

# --- Helper Functions ---
def call_gemini_tracked(trace_name, contents, config):
    """Wraps the Gemini API call with Langfuse telemetry."""
    trace = langfuse.trace(name=trace_name)
    
    sys_inst = config.system_instruction if config else None
    temp = config.temperature if config else None
    
    generation = trace.generation(
        name=trace_name,
        model='gemini-2.5-flash',
        input={"prompt": contents, "system_instruction": sys_inst},
        model_parameters={"temperature": temp}
    )
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=contents,
            config=config
        )
        generation.end(output=response.text)
        langfuse.flush() # Ensure it syncs to local server immediately
        return response
    except Exception as e:
        generation.end(level="ERROR", status_message=str(e))
        langfuse.flush()
        raise e

def get_db_schema(engine):
    """Extract database schema (tables and columns) for LLM context."""
    try:
        insp = inspect(engine)
        schema = []
        for table in insp.get_table_names():
            cols = [f"{c['name']} ({c['type']})" for c in insp.get_columns(table)]
            schema.append(f"Table '{table}' columns: {', '.join(cols)}")
        return "\n".join(schema)
    except Exception as e:
        return f"Error reading schema: {e}"

def parse_json_response(text):
    """Clean and parse JSON from the LLM response."""
    try:
        clean_text = text.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_text)
    except Exception as e:
        st.error("Failed to parse JSON. This usually happens if 'Max Tokens' is too low and the response was cut off mid-generation.")
        st.code(f"...{text[-200:]}") # Show the very end of the text where it broke
        raise e

def create_zip_archive(data_dict, ddl_content):
    """Create a ZIP file containing CSVs and the DDL schema."""
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "a", zipfile.ZIP_DEFLATED, False) as zip_file:
        for table_name, rows in data_dict.items():
            if rows:
                df = pd.DataFrame(rows)
                csv_data = df.to_csv(index=False)
                zip_file.writestr(f"{table_name}.csv", csv_data)
        
        if ddl_content:
            zip_file.writestr("schema.ddl", ddl_content)
            
        zip_file.writestr("full_dataset.json", json.dumps(data_dict, indent=2))
        
    return zip_buffer.getvalue()

def get_db_engine():
    """Create SQLAlchemy engine using Docker compose credentials."""
    db_user = "user"
    db_password = "password"
    db_host = "localhost"
    db_port = "5432"
    db_name = "synth_db"
    return create_engine(f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}")

# --- Sidebar ---
with st.sidebar:
    st.title("Data Assistant")
    
    # Navigation matches mockup design
    nav_selection = st.radio(
        "Navigation", 
        ["🗄️ Data Generation", "💬 Talk to your data"],
        label_visibility="collapsed"
    )
    
    st.divider()
    st.subheader("Database Status")
    try:
        engine = get_db_engine()
        with engine.connect() as conn:
            st.success("✅ PostgreSQL Connected")
            
        # Clean Database Button
        if st.button("🧹 Clean Database", help="Drop all tables and data", use_container_width=True):
            try:
                with st.spinner("Dropping tables..."):
                    meta = MetaData()
                    meta.reflect(bind=engine)
                    meta.drop_all(bind=engine)
                    # Clear chat history since the data it was based on is gone
                    st.session_state.chat_history = [] 
                st.toast("Database cleaned successfully!", icon="✅")
            except Exception as e:
                st.error(f"Failed to clean database: {e}")
                
    except Exception as e:
        st.error("❌ PostgreSQL Not Connected")
        st.caption("Ensure your Docker container is running.")

# --- Main Logic ---
if nav_selection == "🗄️ Data Generation":
    
    # 1. Configuration Card
    with st.container(border=True):
        instructions = st.text_input("Prompt", placeholder="Enter your prompt here...")
        
        st.markdown("<br>", unsafe_allow_html=True)
        
        # File Upload Row
        uploaded_file = st.file_uploader(
            "Upload DDL Schema", 
            type=["sql", "json", "ddl", "txt"],
            help="Supported formats: SQL, JSON, DDL, TXT"
        )
            
        ddl_content = ""
        if uploaded_file is not None:
            ddl_content = uploaded_file.getvalue().decode("utf-8")
        
        st.divider()
        
        # Advanced Parameters Row
        st.markdown("**Advanced Parameters**")
        col_adv1, col_adv2, col_adv3 = st.columns(3)
        with col_adv1:
            temperature = st.slider("Temperature", min_value=0.0, max_value=1.0, value=0.7, step=0.1)
        with col_adv2:
            max_tokens = st.number_input("Max Tokens", min_value=50, max_value=8192, value=8192)
        with col_adv3:
            row_count = st.number_input("Rows per Table", min_value=1, max_value=50, value=3)
        
        st.markdown("<br>", unsafe_allow_html=True)
        generate_btn = st.button("Generate", type="primary")

    # 2. Generation Logic
    if generate_btn:
        if not uploaded_file:
            st.warning("Please upload a DDL schema first.")
        else:
            with st.spinner("Generating synthetic data... this may take a moment."):
                system_instruction = """You are an expert database administrator and data generator. 
                Your task is to generate realistic synthetic data based on a provided SQL DDL schema.
                Output MUST be a valid JSON object where keys are table names (exact match to DDL) and values are arrays of JSON objects representing rows.
                Adhere to all data types, constraints (UNIQUE, NOT NULL), and specifically maintain FOREIGN KEY relationships across tables.
                Do not add extra markdown, only pure JSON."""
                
                prompt = f"""
                DDL Schema:
                {ddl_content}
                
                General Instructions: {instructions if instructions else "Generate realistic, diverse data appropriate for the table column names."}
                Target Row Count: Generate exactly {row_count} rows per table.
                """
                
                try:
                    response = call_gemini_tracked(
                        trace_name="Synthetic Data Generation",
                        contents=prompt,
                        config=types.GenerateContentConfig(
                            system_instruction=system_instruction,
                            temperature=temperature,
                            max_output_tokens=max_tokens,
                            response_mime_type="application/json",
                        )
                    )
                    
                    parsed_data = parse_json_response(response.text)
                    st.session_state.generated_data = parsed_data
                    st.session_state.active_table = list(parsed_data.keys())[0] if parsed_data else None
                except Exception as e:
                    st.error(f"Generation Error: {e}")

    # 3. Data Preview Card
    if st.session_state.generated_data:
        st.markdown("<br>", unsafe_allow_html=True)
        
        with st.container(border=True):
            # Header Row
            col_head1, col_head2 = st.columns([3, 1])
            with col_head1:
                st.markdown("#### Data Preview")
            with col_head2:
                table_names = list(st.session_state.generated_data.keys())
                selected_table = st.selectbox("Select table", table_names, label_visibility="collapsed")
            
            # Data Table
            table_data = st.session_state.generated_data.get(selected_table, [])
            if table_data:
                df = pd.DataFrame(table_data)
                st.dataframe(df, use_container_width=True, hide_index=True)
            else:
                st.info(f"No data generated for {selected_table}.")
            
            st.divider()
            
            # Quick Edit Row
            col_edit1, col_edit2 = st.columns([5, 1])
            with col_edit1:
                feedback = st.text_input(
                    "Edit", 
                    placeholder="Enter quick edit instructions...",
                    label_visibility="collapsed",
                    key="feedback_input"
                )
            with col_edit2:
                submit_edit = st.button("✨ Submit", type="primary", use_container_width=True)
                
            # Quick Edit Logic
            if submit_edit and feedback:
                with st.spinner(f"Applying changes to {selected_table}..."):
                    mod_sys_inst = """You are a data modification agent. 
                    Given an existing JSON array representing rows of a specific SQL table, apply the user's requested changes.
                    Output MUST be ONLY a JSON array representing the updated rows for this table.
                    Maintain the existing schema and data types. Return pure JSON."""
                    
                    mod_prompt = f"""
                    Table Name: {selected_table}
                    Current Data:
                    {json.dumps(table_data, indent=2)}
                    
                    Modification Instruction: {feedback}
                    """
                    
                    try:
                        mod_res = call_gemini_tracked(
                            trace_name="Modify Table Data",
                            contents=mod_prompt,
                            config=types.GenerateContentConfig(
                                system_instruction=mod_sys_inst,
                                temperature=0.3,
                                response_mime_type="application/json",
                            )
                        )
                        updated_table_data = parse_json_response(mod_res.text)
                        st.session_state.generated_data[selected_table] = updated_table_data
                        st.rerun()
                    except Exception as e:
                        st.error(f"Modification Error: {e}")

        # 4. Export & Save Options
        st.markdown("<br>", unsafe_allow_html=True)
        col_exp1, col_exp2 = st.columns(2)
        
        with col_exp1:
            safe_ddl = ddl_content if 'ddl_content' in locals() else "" 
            zip_data = create_zip_archive(st.session_state.generated_data, safe_ddl)
            st.download_button(
                label="📦 Download as ZIP (CSVs + DDL)",
                data=zip_data,
                file_name="synthetic_dataset.zip",
                mime="application/zip",
                use_container_width=True
            )
            
        with col_exp2:
            if st.button("💾 Export to Local PostgreSQL", use_container_width=True):
                try:
                    engine = get_db_engine()
                    with st.spinner("Adapting Schema for PostgreSQL and saving data..."):
                        if 'ddl_content' in locals() and ddl_content:
                            
                            trans_prompt = f"""Convert this SQL DDL to valid PostgreSQL syntax. 
                            - Add DROP TABLE IF EXISTS <table_name> CASCADE; before every CREATE TABLE statement to prevent 'already exists' errors.
                            - Replace AUTO_INCREMENT with SERIAL.
                            - Convert DATETIME to TIMESTAMP.
                            - Convert inline ENUMs to standard VARCHAR with CHECK constraints to avoid multi-statement type creation issues.
                            - Output ONLY the raw SQL code. No markdown formatting.
                            
                            {ddl_content}"""
                            
                            pg_ddl_res = call_gemini_tracked(
                                trace_name="DDL Translation (PostgreSQL)",
                                contents=trans_prompt,
                                config=types.GenerateContentConfig(temperature=0.0)
                            )
                            pg_ddl = pg_ddl_res.text.replace("```sql", "").replace("```", "").strip()
                            
                            raw_conn = engine.raw_connection()
                            try:
                                with raw_conn.cursor() as cursor:
                                    cursor.execute(pg_ddl)
                                raw_conn.commit()
                            finally:
                                raw_conn.close()
                                    
                        for t_name, t_data in st.session_state.generated_data.items():
                            if t_data:
                                df = pd.DataFrame(t_data)
                                df.columns = [col.lower() for col in df.columns]
                                df.to_sql(t_name.lower(), engine, if_exists='append', index=False)
                        
                        st.success("Data successfully saved to PostgreSQL database!")
                except Exception as e:
                    st.error(f"Failed to save to database. Error: {e}")

elif nav_selection == "💬 Talk to your data":
    st.header("Talk to your Data")
    st.markdown("Query your local PostgreSQL database using natural language. Get text summaries, tables, and charts automatically.")
    
    try:
        engine = get_db_engine()
        with engine.connect() as conn:
            pass # Check connection
            
        # Display chat messages from history
        for message in st.session_state.chat_history:
            with st.chat_message(message["role"]):
                st.markdown(message["text"])
                if "sql" in message:
                    with st.expander("Show Generated SQL"):
                        st.code(message["sql"], language="sql")
                if "df" in message and message["df"] is not None and not message["df"].empty:
                    st.dataframe(message["df"], use_container_width=True, hide_index=True)
                if message.get("chart_type") == "bar":
                    st.bar_chart(message["df"], x=message.get("x"), y=message.get("y"))
                elif message.get("chart_type") == "line":
                    st.line_chart(message["df"], x=message.get("x"), y=message.get("y"))

        chat_input = st.chat_input("Ask a question (e.g., 'Show me the top 5 cuisines by average rating')")
        if chat_input:
            st.session_state.chat_history.append({"role": "user", "text": chat_input})
            with st.chat_message("user"):
                st.markdown(chat_input)
                
            with st.chat_message("assistant"):
                with st.spinner("Analyzing data and writing SQL..."):
                    try:
                        # Step A: Text-to-SQL
                        db_schema = get_db_schema(engine)
                        sql_sys_inst = "You are a PostgreSQL expert. Return ONLY a valid JSON object with the key 'sql_query' containing the SQL query. Do not use markdown outside the JSON."
                        sql_prompt = f"Schema:\n{db_schema}\n\nUser Question: {chat_input}"
                        
                        res_sql = call_gemini_tracked(
                            trace_name="NL2SQL Translation",
                            contents=sql_prompt,
                            config=types.GenerateContentConfig(
                                system_instruction=sql_sys_inst,
                                temperature=0.1,
                                response_mime_type="application/json",
                            )
                        )
                        sql_json = parse_json_response(res_sql.text)
                        sql_query = sql_json.get("sql_query")
                        
                        # Step B: Execute SQL
                        with engine.connect() as conn:
                            df = pd.read_sql(text(sql_query), conn)
                        
                        # Step C: Ask LLM how to format the data
                        data_sample = df.head(15).to_dict(orient="records")
                        format_sys_inst = """You are a Data Analyst formatting SQL results. Return ONLY a valid JSON object with:
                        1. 'text_summary': A friendly conversational answer based on the data sample.
                        2. 'chart_type': Choose 'bar', 'line', or 'none' (use 'none' if data cannot be charted).
                        3. 'x_column': Column name for X-axis (if chart_type is not none).
                        4. 'y_column': Column name for Y-axis (if chart_type is not none). Must be numeric."""
                        
                        format_prompt = f"User Question: {chat_input}\nSQL Executed: {sql_query}\nData Sample: {data_sample}"
                        
                        res_format = call_gemini_tracked(
                            trace_name="Data Formatting and Summary",
                            contents=format_prompt,
                            config=types.GenerateContentConfig(
                                system_instruction=format_sys_inst,
                                temperature=0.3,
                                response_mime_type="application/json",
                            )
                        )
                        format_json = parse_json_response(res_format.text)
                        
                        text_summary = format_json.get("text_summary", "Here are your results.")
                        chart_type = format_json.get("chart_type", "none")
                        x_col = format_json.get("x_column")
                        y_col = format_json.get("y_column")
                        
                        # Step D: Display Results
                        st.markdown(text_summary)
                        with st.expander("Show Generated SQL"):
                            st.code(sql_query, language="sql")
                        
                        if not df.empty:
                            st.dataframe(df, use_container_width=True, hide_index=True)
                            if chart_type == "bar" and x_col in df.columns and y_col in df.columns:
                                st.bar_chart(df, x=x_col, y=y_col)
                            elif chart_type == "line" and x_col in df.columns and y_col in df.columns:
                                st.line_chart(df, x=x_col, y=y_col)
                        else:
                            st.info("The query returned no results.")
                            
                        # Save to History
                        st.session_state.chat_history.append({
                            "role": "assistant",
                            "text": text_summary,
                            "sql": sql_query,
                            "df": df,
                            "chart_type": chart_type,
                            "x": x_col,
                            "y": y_col
                        })
                        
                    except Exception as e:
                        st.error(f"Failed to process query: {e}")
            
    except Exception as e:
        st.warning("⚠️ Please ensure PostgreSQL is running via Docker and you have exported data to it first.")