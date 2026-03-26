# Math-for-ML Summative API

This API provides proactive scaling predictions for cloud workloads.

## Hosted API

The API is hosted at: [https://math-for-ml-summative.onrender.com/docs](https://math-for-ml-summative.onrender.com/docs)

## Endpoints

### 1. `POST /train`
Uploads new workload data and retrains the model. Accepts a JSON array of samples (see below for format). Returns a message confirming retraining.

**Example Request Body:**
```
[
	{
		"Job_ID": "job_001",
		"Task_Start_Time": "2026-03-26 08:15:00",
		"Task_End_Time": "2026-03-26 08:16:30",
		"CPU_Utilization": 72.5,
		"Memory_Consumption": 4096,
		"Task_Execution_Time": 900,
		"System_Throughput": 30,
		"Task_Waiting_Time": 40,
		"Data_Source": "prod-cluster-1",
		"Number_of_Active_Users": 320,
		"Network_Bandwidth_Utilization": 110.2,
		"Job_Priority": "High",
		"Error_Rate": 0.01,
		"Scheduler_Type": "FCFS",
		"Resource_Allocation_Type": "Dynamic"
	}
]
```

**Example Response:**
```
{
	"message": "Model retrained successfully."
}
```

### 2. `POST /predict`
Accepts a JSON payload with cloud workload metrics and returns a prediction for CPU utilization and a scaling recommendation.

**Example Request Body:**
```
{
	"Task_Start_Time": "2026-03-26 14:30:00",
	"Number_of_Active_Users": 350,
	"Network_Bandwidth_Utilization": 120.5,
	"Memory_Consumption": 4096,
	"Task_Execution_Time": 850,
	"System_Throughput": 32,
	"Task_Waiting_Time": 45,
	"Error_Rate": 0.02,
	"Job_Priority": "High",
	"Scheduler_Type": "FCFS",
	"Resource_Allocation_Type": "Dynamic"
}
```

**Example Response:**
```
{
	"Predicted_CPU": "72.50%",
	"Action": "WARNING - Proactive Scaling Recommended"
}
```
