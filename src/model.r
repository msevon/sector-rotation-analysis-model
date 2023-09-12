# Compile the C code to create the shared library (if it's not already compiled)
if (!file.exists("moving_average.so")) {
  compile_command <- "gcc -shared -o moving_average.so -fPIC moving_average.c"
  system(compile_command)
}

# Load required libraries
library(quantmod)
library(ggplot2)

# Load the historical stock price data from the CSV file (generated by the Python script)
stock_data <- read.csv("historical_stock_data.csv", stringsAsFactors = FALSE)
stock_data$Date <- as.Date(stock_data$Date)  # Convert Date column to Date type

# Define the symbols for sector ETFs (Technology, Healthcare, Finance)
symbols <- c("XLK", "XLV", "XLF")

# Calculate moving averages for each sector using the C code
ma_period <- 50
sector_names <- c("Technology", "Healthcare", "Finance")

# Initialize a list to store the results
ma_sectors <- list()

for (symbol in symbols) {
  data <- stock_data[stock_data$Symbol == symbol, "Close"]
  
  # Call the C code as an external process
  cmd <- paste("./calculateMovingAverage ", paste(data, collapse = " "), ma_period)
  result <- as.numeric(system(cmd, intern = TRUE))
  
  ma_sectors[[symbol]] <- result
}

# Create a data frame with moving averages
moving_averages <- data.frame(Date = stock_data$Date, ma_sectors)

# Load the allocation strategy functions from the allocation_strategy.R script
source("allocation_strategy.R")

# Define a list of allocation strategies
allocation_strategies <- list(strategy1, strategy2, strategy3, strategy4)

# Use the compare_allocation_strategies function to find the best strategy
best_allocation_strategy <- compare_allocation_strategies(moving_averages, sector_names, 
                                                          strategies = allocation_strategies,
                                                          metric = "return")

# Apply the best allocation strategy to the moving averages data
allocated_sectors <- best_allocation_strategy(moving_averages, sector_names)
moving_averages$Allocated_Sector <- allocated_sectors

# Create a line plot to visualize sector rotation
ggplot(data = moving_averages, aes(x = Date)) +
  lapply(sector_names, function(sector) {
    geom_line(aes_string(y = sector, color = sector))
  }) +
  labs(title = "Sector Rotation Model",
       x = "Date",
       y = "Moving Average",
       color = "Sector") +
  scale_color_manual(values = c(Technology = "blue", Healthcare = "green", Finance = "red")) +
  theme_minimal()
