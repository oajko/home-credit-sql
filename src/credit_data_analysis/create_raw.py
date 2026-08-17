import os
import duckdb
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
SPILL_DIR = Path("/var/tmp/duckdb_spill")

def connection():
    con = duckdb.connect()
    con.execute("INSTALL postgres; LOAD postgres;")

    con.execute("SET memory_limit='8GB'")
    SPILL_DIR.mkdir(parents = True, exist_ok = True)
    con.execute(f"SET temp_directory='{SPILL_DIR}'")

    host = os.getenv("DB_HOST")
    port = os.getenv("DB_PORT")
    db_name = os.getenv("DB_NAME")
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASS")
    con.execute(
        f"ATTACH 'host={host} port={port} dbname={db_name} "
        f"user={user} password={password}' "
        "AS pg (TYPE postgres)"
    )
    return con

def main():
    con = connection()
    folder = Path("data/parquet_files/train")

    for file in sorted(folder.glob("*.parquet")):
        table_name = file.stem.replace("-", "_").lower()
        print(f"Running {file}")
        try:
            con.execute(
                f"CREATE OR REPLACE TABLE pg.{table_name} AS "
                f"SELECT * FROM read_parquet('{file}')"
            )
        except Exception as e:
            print("failed")

if __name__ == "__main__":
    main()