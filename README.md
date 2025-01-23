# Marketing-Analytics
## Data Analysis Project: SQL to SSIS to Power BI Integration with Python Predictions

## Introduction
This project demonstrates the full workflow of integrating SQL-based database relations with SSIS for ETL, Power BI for visualization and analysis, followed by Python-based predictive modeling. The aim is to establish a robust end-to-end data pipeline, starting from data organization in SQL, moving through data transformation in SSIS, visualization in Power BI, and culminating in advanced analysis and predictions using Python.

---

## Step 1: Building Database Relations with SQL
### Objective
Design and establish relational database structures to support efficient data analysis and visualization.

### Process
1. **Data Preparation**:
   - Consolidate raw datasets into structured tables.
   - Clean data by handling missing values, duplicates, and inconsistencies.

2. **Database Design**:
   - Define primary and foreign key relationships between tables.
   - Normalize data to eliminate redundancy and improve integrity.

3. **SQL Scripts**:
   Below is a sample SQL script to create the database and establish relations:
   ```sql
   CREATE DATABASE SalesAnalytics;
   USE SalesAnalytics;

   CREATE TABLE Customers (
       CustomerID INT PRIMARY KEY,
       Name VARCHAR(255),
       Email VARCHAR(255),
       JoinDate DATE
   );

   CREATE TABLE Orders (
       OrderID INT PRIMARY KEY,
       CustomerID INT,
       OrderDate DATE,
       TotalAmount DECIMAL(10, 2),
       FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
   );

   CREATE TABLE Products (
       ProductID INT PRIMARY KEY,
       ProductName VARCHAR(255),
       Category VARCHAR(255),
       Price DECIMAL(10, 2)
   );

   CREATE TABLE OrderDetails (
       OrderDetailID INT PRIMARY KEY,
       OrderID INT,
       ProductID INT,
       Quantity INT,
       FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
       FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
   );
   ```

4. **Data Insertion**:
   Populate the tables with relevant data using `INSERT` statements or automated ETL tools.

---

## Step 2: ETL with SSIS
### Objective
Extract, transform, and load data from multiple sources into the SQL Server database using SSIS.

### Process
1. **Create an SSIS Project**:
   - Use SQL Server Data Tools (SSDT) to create a new SSIS project.

2. **Define Data Flow**:
   - Configure `Data Flow Tasks` to extract data from flat files, Excel sheets, or other databases.
   - Use transformations like `Lookup`, `Derived Column`, `Conditional Split`, and `Aggregate` to clean and shape data.

3. **Load Data**:
   - Use `OLE DB Destination` to load transformed data into the SQL Server database.

4. **Schedule ETL Jobs**:
   - Deploy the SSIS package to the SQL Server and schedule it using SQL Server Agent for automated updates.

---

## Step 3: Integrating SQL with Power BI
### Objective
Visualize SQL data in Power BI for actionable insights.

### Process
1. **Connect to SQL Server**:
   - Use the "Get Data" option in Power BI to connect to the SQL Server database.

2. **Data Transformation**:
   - Use Power Query to shape and transform data for analysis.
   - Merge tables using relationships defined in SQL.

3. **Create Visualizations**:
   - Design dashboards and reports for KPIs, trends, and performance metrics.

4. **Publish Reports**:
   - Publish dashboards to the Power BI service for sharing and collaboration.

---

## Step 4: Predictive Modeling with Python
### Objective
Leverage Python for advanced analytics and predictions using data exported from Power BI.

### Process
1. **Export Data**:
   - Export refined datasets from Power BI as CSV files for use in Python.

2. **Data Preprocessing**:
   - Load data into Python using `pandas`.
   - Perform exploratory data analysis (EDA) to identify trends and correlations.

3. **Model Development**:
   - Build machine learning models using `scikit-learn`.
   - Example: Predict sales using a regression model:
   ```python
   import pandas as pd
   from sklearn.model_selection import train_test_split
   from sklearn.linear_model import LinearRegression
   from sklearn.metrics import mean_squared_error

   # Load data
   data = pd.read_csv('sales_data.csv')

   # Feature selection
   X = data[['CustomerID', 'TotalAmount']]
   y = data['SalesPrediction']

   # Split data
   X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

   # Train model
   model = LinearRegression()
   model.fit(X_train, y_train)

   # Evaluate model
   predictions = model.predict(X_test)
   mse = mean_squared_error(y_test, predictions)
   print(f"Mean Squared Error: {mse}")
   ```

4. **Visualization**:
   - Use `matplotlib` or `seaborn` for visualizing predictions and residuals.

5. **Integration**:
   - Feed predictions back into Power BI for enhanced decision-making.

---

## Documentation and Version Control
- Maintain detailed documentation for SQL schemas, SSIS packages, Power BI dashboards, and Python scripts.
- Use GitHub for version control and collaboration.

---

## README
### Project Overview
- **Title**: SQL to SSIS to Power BI Integration with Python Predictions
- **Description**: A comprehensive workflow integrating SQL database design, SSIS ETL, Power BI visualization, and Python-based predictions.

### Prerequisites
- SQL Server
- SSIS (SQL Server Integration Services)
- Power BI Desktop
- Python (with `pandas`, `scikit-learn`, `matplotlib`)

### Steps to Run
1. Set up the SQL database using provided scripts.
2. Build and deploy the SSIS package for ETL.
3. Connect Power BI to the SQL Server.
4. Export data from Power BI and run Python scripts for predictions.

### Outputs
- SQL-based relational database.
- SSIS ETL package.
- Power BI dashboards.
- Python-generated predictions.

### Contribution
Contributions are welcome! Submit a pull request with proposed changes or improvements.
