# DataSynth AI

This project uses Python, Streamlit, Docker, and PostgreSQL to generate synthetic data based on DDL schemas and allows you to chat with your database using natural language (NL2SQL). It is powered by the Gemini 2.5 Flash API via Google Cloud Vertex AI, with full local telemetry tracked via Langfuse.

## Prerequisites

* **Python 3.9+** installed on your Mac or PC.

* **A running Docker Engine**. You can use:

  * **OrbStack** *(Recommended for Mac)*: A fast, lightweight, and efficient drop-in replacement for Docker Desktop.

  * **Colima**: A free, open-source, CLI-based alternative for Mac (install via brew install colima and run colima start).

  * **Docker Desktop**: The standard option for Mac/Windows.

* **Google Cloud CLI** installed (gcloud).

## Step-by-Step Guide

### 1. Authenticate with Google Cloud (ADC)

In your terminal, set up your Application Default Credentials and link it to your Google Cloud project (so Vertex AI knows where to route requests):

    gcloud auth application-default login --project=your-project-id

### 2. Start PostgreSQL and Langfuse

Open your terminal in the project directory and run:

    docker-compose up -d

*Note:* This will download and start both the PostgreSQL database (port 5432) and the local Langfuse tracking server (port 3000) in the background.

### 3. Configure Local Langfuse (Observability)

Since Langfuse is running locally on your machine, you need to generate API keys to track the LLM calls:

* Open http://localhost:3000 in your browser.

* Sign up *(you can use any dummy email/password as it is completely local)* and create a new project (e.g., "DataSynth").

* Navigate to **Settings > API Keys** in the left sidebar and click **Create new API Key**.

* Copy your **Public Key** (pk-lf-...) and **Secret Key** (sk-lf-...).

* Open app.py and replace the public_key and secret_key in the Langfuse initialization block with your new keys:

    langfuse = Langfuse(
        secret_key="your-secret-key",
        public_key="your-public-key",
        host="http://localhost:3000"
    )

### 4. Set up Python Environment

Create a virtual environment and install the dependencies:

    # Create virtual environment
    python3 -m venv venv

    # Activate virtual environment
    # On Mac/Linux:
    source venv/bin/activate
    # On Windows:
    venv\Scripts\activate

    # Install requirements
    pip install -r requirements.txt

### 5. Run the Streamlit Application

Start the Streamlit UI by running:

    streamlit run app.py

A new browser tab will open automatically at http://localhost:8501.

## Features & Usage

### Phase 1: Data Generation

* Ensure the "Database Status" in the sidebar shows **PostgreSQL Connected**.

* Upload a SQL/DDL file in the **Data Generation** tab.

* Tweak your prompt and adjust "Advanced Parameters" *(Increase **Rows per Table** to generate more data, up to the API token limit)*.

* Click **Generate** to create synthetic data.

* Preview the tables, edit them iteratively via the quick edit box.

* Click **Export to Local PostgreSQL**. *(This automatically translates schemas and drops existing tables to prevent conflicts)*.

### Phase 2: Talk to your Data

* Navigate to the **Talk to your data** section via the sidebar.

* Ask natural language questions about the synthetic data you just exported (e.g., "Show me the top 5 cuisines by average rating").

* The app will automatically write the SQL, execute it locally, and return text summaries alongside dynamic data tables and charts!

### Observability with Langfuse

All interactions with the Gemini LLM are automatically logged to your local Langfuse instance.

* **View Traces:** Go to http://localhost:3000 and click on **Traces** to see every prompt, response, latency, and the exact token usage.

* **Trace Details:** Traces are categorized automatically (e.g., "Synthetic Data Generation", "Modify Table Data", "NL2SQL Translation") for easy debugging and cost/latency analysis.

### Database Maintenance

* If you want to start over, click the **Clean Database** button in the sidebar to safely drop all tables and clear your chat history.