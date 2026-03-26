from fastapi import FastAPI
from linear_regression.predict import proactive_scaling_engine, RawData
from linear_regression.train import TrainingData, train_model
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

origins = [
    "https://math-for-ml-summative.onrender.com/"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.post("/predict")
async def predict(raw_data: RawData):
    """
    Expects a JSON payload matching the RawData model, e.g.:
    {
        "Task_Start_Time": "2023-10-27 08:30:00",
        "Number_of_Active_Users": 100,
        "Network_Bandwidth_Utilization": 100.0,
        "Memory_Consumption": 4096.0,
        "Task_Execution_Time": 500.0,
        "System_Throughput": 20.0,
        "Task_Waiting_Time": 50.0,
        "Error_Rate": 0.01,
        "Job_Priority": "High",
        "Scheduler_Type": "Round Robin",
        "Resource_Allocation_Type": "Dynamic"
    }
    Returns the predicted CPU utilization and recommended scaling action.
    """
    return proactive_scaling_engine(raw_data)


@app.post("/train")
async def train(training_data: list[TrainingData]):
    """
    Expects a JSON array of training data matching the TrainingData model, e.g.:
    [
        {
            "Job_ID": "job_123",
            "Task_Start_Time": "2023-10-27 08:30:00",
            "Task_End_Time": "2023-10-27 08:40:00",
            "CPU_Utilization": 75.0,
            "Memory_Consumption": 4096.0,
            "Task_Execution_Time": 500.0,
            "System_Throughput": 20.0,
            "Task_Waiting_Time": 50.0,
            "Data_Source": "IoT",
            "Number_of_Active_Users": 100,
            "Network_Bandwidth_Utilization": 100.0,
            "Job_Priority": "High",
            "Error_Rate": 0.01,
            "Scheduler_Type": "Round Robin",
            "Resource_Allocation_Type": "Dynamic"
        }
    ]
    Trains the model with the provided data and returns a success message.
    """
    # rename columns to match the training dataset
    df_new = pd.DataFrame([data.model_dump() for data in training_data])
    df_new.rename(columns={
        "Job_ID": "Job_ID",
        "Task_Start_Time": "Task_Start_Time",
        "Task_End_Time": "Task_End_Time",
        "CPU_Utilization": "CPU_Utilization (%)",
        "Memory_Consumption": "Memory_Consumption (MB)",
        "Task_Execution_Time": "Task_Execution_Time (ms)",
        "System_Throughput": "System_Throughput (tasks/sec)",
        "Task_Waiting_Time": "Task_Waiting_Time (ms)",
        "Data_Source": "Data_Source",
        "Number_of_Active_Users": "Number_of_Active_Users",
        "Network_Bandwidth_Utilization": "Network_Bandwidth_Utilization (Mbps)",
        "Job_Priority": "Job_Priority",
        "Scheduler_Type": "Scheduler_Type",
        "Resource_Allocation_Type": "Resource_Allocation_Type",
        "Error_Rate": "Error_Rate (%)"
    }, inplace=True)

    train_model(df_new)

    # append new data to existing dataset for persistence
    df_new.to_csv('./linear_regression/data/cloud_workload_dataset.csv', mode='a', header=False, index=False)

    return {
        "message": f"Received {len(training_data)} training records. Model retrained successfully."
    }