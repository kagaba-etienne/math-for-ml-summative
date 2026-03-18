# Proactive Scaling for African Digital Infrastructure

**Mission & Problem:** This project addresses the scalability bottleneck in African digital infrastructure by predicting CPU utilization through regression analysis. The goal is to build a proactive scaling tool that identifies high-traffic patterns early, preventing system crashes and optimizing resource allocation in cloud environments.

**Data & Source:** 5,000 Cloud Workload Infrastructure Logs (Kaggle) containing user counts, task priority, and multi-scheduler metrics.

**Champion Model:** Decision Tree Regressor (Depth 5) was selected as the best-performing model with the least loss (MSE: 532.77) compared to SGD and Random Forest.