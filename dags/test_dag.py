import datetime
import time

from airflow.sdk import DAG, task

with DAG(
    dag_id="test_dag", start_date=datetime.datetime(2021, 1, 1), schedule="@daily"
):

    @task
    def hello_world():
        time.sleep(5)
        print("Hello world, from Airflow!")

    @task
    def goodbye_world_v2():
        time.sleep(5)
        print("Goodbye world, from Airflow! Version 2")

    hello_world() >> goodbye_world_v2()
