# 🚀 AI-Assisted Log Anomaly Detection (AIOps)

An intelligent log analysis and anomaly detection pipeline designed to bridge traditional DevOps log monitoring with Machine Learning (AIOps). This project contrasts standard rule-based alerting against unsupervised machine learning using Isolation Forest to detect abnormal system behavior in application and infrastructure logs.

---

## 📌 Project Overview

In cloud-native and production environments, analyzing massive volumes of distributed logs manually is impossible. Static rule-based alerts often lead to alert fatigue or completely miss subtle patterns. 

This repository implements two complementary paradigms:
1. **Rule-Based Log Analysis (`simple_log_analysis.py`)**: Uses deterministic rules, regex parsing, and time-window aggregation to catch sudden volume spikes of `ERROR` logs.
2. **Machine Learning-Driven AIOps (`aiops_log_analysis.py`)**: Transforms unstructured logs into numerical features and applies **Scikit-learn's Isolation Forest** to automatically detect abnormal events without hardcoded threshold rules.

---

## 🏗️ Architecture & Workflow

```text
       +-----------------------+
       |   system_logs.txt     |
       +-----------+-----------+
                   |
       +-----------v-----------+
       | Data Extraction &     |
       | Pandas Preprocessing  |
       +-----------+-----------+
                   |
       +-----------+-------------------------+
       |                                     |
       v                                     v
+-------------------------------+ +----------------------------------+
| Approach 1: Rule-Based        | | Approach 2: ML-Based (AIOps)     |
| • Regex field extraction      | | • Feature Engineering:           |
| • 30s Window Binning (Floor)  | |   - Severity Score (1-4)         |
| • Threshold Trigger (> 3)     | |   - Message Length               |
+---------------+---------------+ | • Isolation Forest Model         |
                |                 +----------------+-----------------+
                v                                  v
+-------------------------------+ +----------------------------------+
|  🚨 Static Spike Alerts       | |  ❌ Behavioral Outlier Anomalies  |
+-------------------------------+ +----------------------------------+
