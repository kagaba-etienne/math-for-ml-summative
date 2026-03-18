import pickle
import numpy as np
import pandas as pd
import json
import warnings
warnings.filterwarnings("ignore")

def proactive_scaling_engine(raw_data):
    """
    INPUT: Dictionary of raw server metrics.
    Example: {
        'Task_Start_Time': '2023-10-27 08:30:00',
        'Number_of_Active_Users': 450,
        'Network_Bandwidth_Utilization (Mbps)': 200,
        'Memory_Consumption (MB)': 4096,
        'Task_Waiting_Time (ms)': 50,
        'Error_Rate (%)': 0.01,
        'Job_Priority': 'High',
        'Scheduler_Type': 'Round Robin',
        'Resource_Allocation_Type': 'Dynamic'
    }
    """
    # Load the trained model and scaler
    with open('scaling_model/model.pkl', 'rb') as f_m:
        model = pickle.load(f_m)
    with open('scaling_model/scaler.pkl', 'rb') as f_s:
        scaler = pickle.load(f_s)

    # Transform raw input data into the feature vector expected by the model

    # A. Time Transformation (Cyclical)
    dt = pd.to_datetime(raw_data['Task_Start_Time'])
    hour = dt.hour
    hour_sin = np.sin(2 * np.pi * hour / 24)
    hour_cos = np.cos(2 * np.pi * hour / 24)

    # B. Priority Mapping (Ordinal)
    dt = pd.to_datetime(raw_data['Task_Start_Time'])
    hour_sin = np.sin(2 * np.pi * dt.hour / 24)
    hour_cos = np.cos(2 * np.pi * dt.hour / 24)

    # Priority -> Numbers
    p_map = {'Low': 0, 'Medium': 1, 'High': 2}
    priority_val = p_map.get(raw_data['Job_Priority'], 0)

    # One-Hot Encoding Logic
    sched = raw_data['Scheduler_Type']
    alloc = raw_data['Resource_Allocation_Type']

    # Assemble the feature vector in the same order as training
    features = [
        raw_data['Memory_Consumption (MB)'],
        raw_data['Task_Execution_Time (ms)'],
        raw_data['System_Throughput (tasks/sec)'],
        raw_data['Task_Waiting_Time (ms)'],
        raw_data['Number_of_Active_Users'],
        raw_data['Network_Bandwidth_Utilization (Mbps)'],
        priority_val,
        raw_data['Error_Rate (%)'],
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
raw_log = {
    'Task_Start_Time': '2026-03-18 09:00:00',
    'Memory_Consumption (MB)': 8192,
    'Task_Execution_Time (ms)': 1200,
    'System_Throughput (tasks/sec)': 45,
    'Task_Waiting_Time (ms)': 150,
    'Number_of_Active_Users': 800,
    'Network_Bandwidth_Utilization (Mbps)': 500,
    'Job_Priority': 'High',
    'Error_Rate (%)': 0.02,
    'Scheduler_Type': 'FCFS',
    'Resource_Allocation_Type': 'Dynamic'
}
print(json.dumps(proactive_scaling_engine(raw_log), indent=2))