# Credit Analysis from Home Credit Group Data

The purpose of this repository is to learn using SQL for real dataset using the PGAdmin4 GUI/ PSQL cli rather than LeetCode's gamified environment. The data selected is Home Credit dataset from Kaggle, link below the paragraph. Chosen for multi-table and large size.

Data is from https://www.kaggle.com/competitions/home-credit-credit-risk-model-stability

### Repo Structure
- sql/ showcases sql queries
- data/  (gitignored) is the unzipped Home Credit data

### Steps to Setup Repository
Requires:
- uv
- PostgreSQL 17+
- ~30GB of free disk space


1. **Get the data**:
- Follow the link to the competition: https://www.kaggle.com/competitions/home-credit-credit-risk-model-stability
- Agree to the competition rules and download all the data.
- Unzip, rename file as data, and move to the root of this repo


2. **Setup .env**
- Run cp .env.example .env
- Fill variables for Postgres server details


3. **Start Postgres**
- Run sudo systemctl start postgresql


4. **Load Data to SQL**
- run uv sync then run uv run credit-data-analysis