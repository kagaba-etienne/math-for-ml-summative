# Proactive Scaling for African Digital Infrastructure

**Mission & Problem:** This project addresses the scalability bottleneck in African digital infrastructure by predicting CPU utilization through regression analysis. The goal is to build a proactive scaling tool that identifies high-traffic patterns early, preventing system crashes and optimizing resource allocation in cloud environments.

**Data & Source:** 5,000 Cloud Workload Infrastructure Logs (Kaggle) containing user counts, task priority, and multi-scheduler metrics.

**Champion Model:** Decision Tree Regressor (Depth 5) was selected as the best-performing model with the least loss (MSE: 532.77) compared to SGD and Random Forest.

# Demo Video

[![Watch the video](https://img.youtube.com/vi/osHa5klEXs0/maxresdefault.jpg)](https://www.youtube.com/watch?v=osHa5klEXs0)

# App Screenshots

Below are screenshots of the app pages:

<div style="display: flex; gap: 16px; ">
  <img src="./Screenshot from 2026-03-26 20-03-30.png" width="300" alt="Home Page" />
  <img src="./Screenshot from 2026-03-26 20-03-35.png" width="300" alt="Home Page" />
</div>


# How to Run the App

1. **Install Flutter:**
  - Follow the official guide: https://docs.flutter.dev/get-started/install

2. **Clone this repository:**
  - `git clone git@github.com:kagaba-etienne/math-for-ml-summative.git` or `git clone https://github.com/kagaba-etienne/math-for-ml-summative.git`
  - `cd flutter_app`

3. **Get dependencies:**
  - Run: `flutter pub get`

4. **Run the app:**
  - Connect a device or start an emulator.
  - Run: `flutter run`

5. **Build for release (optional):**
  - Android: `flutter build apk`
  - iOS: `flutter build ios`

For more details, see the [Flutter documentation](https://docs.flutter.dev/).