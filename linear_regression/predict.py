import pickle
import numpy as np
import pandas as pd
import json
import warnings
warnings.filterwarnings("ignore")
from typing import Annotated, Literal
from pydantic import BaseModel, Field

# Load the trained model and scaler
with open('./linear_regression/scaling_model/model.pkl', 'rb') as f_m:
    model = pickle.load(f_m)
with open('./linear_regression/scaling_model/scaler.pkl', 'rb') as f_s:
    scaler = pickle.load(f_s)

class RawData(BaseModel):
    Task_Start_Time: str
    Number_of_Active_Users: int
    Network_Bandwidth_Utilization: float
    Memory_Consumption: float
    Task_Execution_Time: float
    System_Throughput: float
    Task_Waiting_Time: float
    Error_Rate: Annotated[float, Field(ge=0, le=100)]
    Job_Priority: Literal['Low', 'Medium', 'High']
    Scheduler_Type: Literal['Round Robin', 'Priority-Based', 'FCFS', 'ASB-Dynamic-CapsNet']
    Resource_Allocation_Type: Literal['Dynamic', 'Static']

def proactive_scaling_engine(raw_data: RawData):
    """
    Predict CPU utilization and scaling action from raw server metrics.

    Args:
        raw_data (RawData): Pydantic model containing server metrics with strict typing.

    Example:
        RawData(
            Task_Start_Time='2023-10-27 08:30:00',
            Number_of_Active_Users=450,
            Network_Bandwidth_Utilization=200.0,
            Memory_Consumption=4096.0,
            Task_Execution_Time=500.0,
            System_Throughput=20.0,
            Task_Waiting_Time=50.0,
            Error_Rate=0.01,
            Job_Priority='High',
            Scheduler_Type='Round Robin',
            Resource_Allocation_Type='Dynamic'
        )
    Returns:
        dict: Predicted CPU utilization and recommended scaling action.
    """

    # Transform raw input data into the feature vector expected by the model

    # A. Time Transformation (Cyclical)
    dt = pd.to_datetime(raw_data.Task_Start_Time)
    hour = dt.hour
    hour_sin = np.sin(2 * np.pi * hour / 24)
    hour_cos = np.cos(2 * np.pi * hour / 24)

    # Priority Mapping (Ordinal)
    p_map = {'Low': 0, 'Medium': 1, 'High': 2}
    priority_val = p_map.get(raw_data.Job_Priority, 0)

    # One-Hot Encoding Logic
    sched = raw_data.Scheduler_Type
    alloc = raw_data.Resource_Allocation_Type

    # Assemble the feature vector in the same order as training
    features: list[float] = [
        raw_data.Memory_Consumption,
        raw_data.Task_Execution_Time,
        raw_data.System_Throughput,
        raw_data.Task_Waiting_Time,
        raw_data.Number_of_Active_Users,
        raw_data.Network_Bandwidth_Utilization,
        priority_val,
        raw_data.Error_Rate,
        hour,
        hour_sin,
        hour_cos,
        1 if sched == 'ASB-Dynamic-CapsNet' else 0,
        1 if sched == 'FCFS' else 0,
        1 if sched == 'Priority-Based' else 0,
        1 if sched == 'Round Robin' else 0,
        1 if alloc == 'Dynamic' else 0,
        1 if alloc == 'Static' else 0
    ]

    # Scale the features and make prediction
    final_input = scaler.transform([features])
    prediction = model.predict(final_input)[0]

    # Determine action based on predicted CPU utilization
    if prediction > 80:
        action = "CRITICAL - Scale Up Instantly"
    elif prediction > 60:
        action = "WARNING - Proactive Scaling Recommended"
    else:
        action = "STABLE - System Healthy"

    return {
        "Predicted_CPU": f"{prediction:.2f}%",
        "Action": action
    }

#--- TEST ---
if __name__ == "__main__":
    raw_log = RawData(
        Task_Start_Time='2026-03-18 09:00:00',
        Memory_Consumption=8192,
        Task_Execution_Time=1200,
        System_Throughput=45,
        Task_Waiting_Time=150,
        Number_of_Active_Users=800,
        Network_Bandwidth_Utilization=500,
        Job_Priority='High',
        Error_Rate=0.02,
        Scheduler_Type='FCFS',
        Resource_Allocation_Type='Dynamic'
    )
    print(json.dumps(proactive_scaling_engine(raw_log), indent=2))