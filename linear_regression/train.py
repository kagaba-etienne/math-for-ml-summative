import pandas as pd
import numpy as np
import pickle
from typing import Annotated, Literal
from pydantic import BaseModel, Field
from sklearn.tree import DecisionTreeRegressor
from .predict import model

class TrainingData(BaseModel):
    Job_ID: str
    Task_Start_Time: str
    Task_End_Time: str
    CPU_Utilization: float
    Memory_Consumption: float
    Task_Execution_Time: float
    System_Throughput: float
    Task_Waiting_Time: float
    Data_Source: str
    Number_of_Active_Users: int
    Network_Bandwidth_Utilization: float
    Job_Priority: Literal['Low', 'Medium', 'High']
    Error_Rate: Annotated[float, Field(ge=0, le=100)]
    Scheduler_Type: Literal['Round Robin', 'Priority-Based', 'FCFS', 'ASB-Dynamic-CapsNet']
    Resource_Allocation_Type: Literal['Dynamic', 'Static']

df_old = pd.read_csv('./linear_regression/data/cloud_workload_dataset.csv')

def clean_data(df: pd.DataFrame) -> pd.DataFrame:
  """
  Cleans the input DataFrame by performing necessary preprocessing steps.
  """
  # Convert Task_Start_Time to datetime and extract hour features
  df['Task_Start_Time'] = pd.to_datetime(df['Task_Start_Time'])
  df['hour'] = df['Task_Start_Time'].dt.hour
  df['hour_sin'] = np.sin(2 * np.pi * df['hour'] / 24)
  df['hour_cos'] = np.cos(2 * np.pi * df['hour'] / 24)
  
  # Label encoding for Job_Priority
  priority_map = {'Low': 0, 'Medium': 1, 'High': 2}
  df['Job_Priority'] = df['Job_Priority'].map(priority_map)
  
  # One-hot encoding for categorical columns
  cat_cols = ['Scheduler_Type', 'Resource_Allocation_Type']
  df = pd.get_dummies(df, columns=cat_cols)
  
  # Drop unnecessary columns
  cols_to_drop = ['Job_ID', 'Task_Start_Time', 'Task_End_Time', 'Data_Source']
  df_cleaned = df.drop(columns=cols_to_drop)
  
  return df_cleaned

def train_model(df_new: pd.DataFrame):
  global model
  # Combine old and new data
  df_combined = pd.concat([df_old, df_new], ignore_index=True)
  
  # Preprocess the combined dataset (handle categorical variables, missing values, etc.)
  df_combined = clean_data(df_combined)
  
  # Define features and target variable
  X = df_combined.drop(columns=['CPU_Utilization (%)'])
  y = df_combined['CPU_Utilization (%)']
  
  # Train a Decision Tree Regressor
  dt_model = DecisionTreeRegressor(max_depth=5, random_state=42)
  dt_model.fit(X, y) # type: ignore
  
  # Save the model
  with open('./linear_regression/scaling_model/model.pkl', 'wb') as f:
    pickle.dump(dt_model, f)
  with open('./linear_regression/scaling_model/model.pkl', 'rb') as f:
    model = pickle.load(f)
  
  return dt_model
