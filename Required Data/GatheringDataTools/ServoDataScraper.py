import requests
from bs4 import BeautifulSoup
import csv
import os
import numpy as np
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options

# Directory of the current file
THIS_FILE_DIR = os.path.dirname(os.path.abspath(__file__)) + os.sep

# URL of the website
BASE_URL = "https://servodatabase.com/servos/all?page={}"
SERVO_CITY_URL = "https://www.servocity.com/servos/"

# CSV file to store the data
CSV_FILE = THIS_FILE_DIR + "../servo_data.csv"

# File to track the last scraped page
LAST_PAGE_FILE = THIS_FILE_DIR + "last_page_servo.txt"

unique_servos = set()

def initialize_unique_servos():
    if os.path.exists(CSV_FILE):
        with open(CSV_FILE, mode='r', encoding='utf-8') as file:
            reader = csv.reader(file)
            next(reader)  # Skip the header row
            for row in reader:
                if len(row) > 1:  # Ensure the row has at least 2 columns
                    unique_servos.add(row[1])

def scrape_servo_city_servo():
    # Set up Selenium WebDriver
    chrome_options = Options()
    # chrome_options.add_argument("--headless")  # Run in headless mode
    chrome_options.add_argument("--no-sandbox")
    driver = webdriver.Chrome(options=chrome_options)

    try:
        driver.get(SERVO_CITY_URL)
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "productTable")))

        driver.find_element(By.ID, "columnToggleBtn").click()
        driver.find_element(By.XPATH, "//span[@data-column-id='data-filter_weight' and contains(@class, 'navList-action')]").click()
        driver.find_element(By.XPATH, "//span[@data-column-id='data-filter_brand' and contains(@class, 'navList-action')]").click()

        tables = driver.find_elements(By.CLASS_NAME, "productTable")
        data = []

        for table in tables:
            rows = table.find_elements(By.TAG_NAME, "tr")[1:]  # Skip the header row
            for row in rows:
                cols = row.find_elements(By.TAG_NAME, "td")
                if len(cols) < 7 or not row.text:  # Ensure there are enough columns for all data fields
                    continue
                servo_company = cols[9].text.strip()
                servo_model = cols[0].text.strip()
                torque = convert_torque(robust_float64(cols[2].text.split(" ")[0]))
                price = robust_float64(cols[11].text.split("$")[-1])
                speed = robust_float64(cols[3].text.split(" ")[0])
                weight = robust_float64(cols[5].text.split('g')[0].strip())
                servo_data = [
                    servo_company,  # Company
                    servo_model,  # Model
                    torque,  # Torque (converted to kg.cm)
                    speed,  # Speed (formatted)
                    weight,  # Weight
                    price,  # Price
                    SERVO_CITY_URL  # URL
                ]
                if servo_model not in unique_servos:
                    unique_servos.add(servo_model)
                    data.append(servo_data)

        write_to_csv(data)

    finally:
        driver.quit()

def robust_int64(str_val:str):
    try:
        str_val = str_val.replace(",", "")
        return np.int64(str_val)
    except ValueError:
        return None

def robust_float64(str_val:str):
    try:
        str_val = str_val.replace(",", "")
        return np.float64(str_val)
    except ValueError:
        return None
    
def oz_to_g(oz):
    return 0.0283495 * oz * 1000

# Function to convert torque from oz.in to kg.cm
def convert_torque(torque):
    return torque * 0.072

# Function to scrape data from a single page
def scrape_page(page_number):
    url = BASE_URL.format(page_number)
    max_retries = 20
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()  # Raise an HTTPError for bad responses (4xx and 5xx)
            break  # Exit the loop if the request is successful
        except requests.exceptions.RequestException as e:
            print(f"Error fetching page {page_number} (Attempt {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                import time
                time.sleep(2)  # Wait for 2 seconds before retrying
            else:
                return [], True

    soup = BeautifulSoup(response.text, 'html.parser')
    table = soup.find("table", {"class": "servos"})
    if not table:
        print(f"No table found on page {page_number}")
        return [], True

    rows = table.find_all("tr")[1:]  # Skip the header row
    data = []
    for row in rows:
        cols = row.find_all("td")
        if len(cols) < 7:  # Ensure there are enough columns for all data fields
            continue
        
        servo_company = cols[0].text.strip()
        servo_model = cols[1].text.split('*')[0].strip()
        if servo_model not in unique_servos:
            unique_servos.add(servo_model)
            if "add" in cols[6].text or "add" in cols[10].text or "add" in cols[3].text or "add" in cols[5].text:
                continue
            torque = convert_torque(robust_float64(cols[5].text.split("\n")[-2].split(" ")[1]))
            price = robust_float64(cols[10].text.split("$")[-1])
            speed = robust_float64(cols[6].text.split("\n")[-2].split(" ")[1])
            weight = oz_to_g(robust_float64(cols[3].text.split("oz")[0].strip()))
            servo_data = [
                servo_company,  # Company
                servo_model,  # Model
                torque,  # Torque (converted to kg.cm)
                speed,  # Speed (formatted)
                weight,  # Weight
                price,  # Price
                url
            ]
            data.append(servo_data)
    return data, False

# Function to write data to CSV
def write_to_csv(data):
    with open(CSV_FILE, mode='a', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerows(data)

# Function to read the last scraped page
def read_last_page():
    if os.path.exists(LAST_PAGE_FILE):
        with open(LAST_PAGE_FILE, mode='r', encoding='utf-8') as file:
            return int(file.read().strip())
    return 1

# Function to save the last scraped page
def save_last_page(page_number):
    with open(LAST_PAGE_FILE, mode='w', encoding='utf-8') as file:
        file.write(str(page_number))

# Main function to scrape all pages
def scrape_all_pages():
    page_number = read_last_page()
    while True:
        print(f"Scraping page {page_number}...")
        data, done = scrape_page(page_number)
        if not data:  # Stop if no data is found
            if done or page_number>167:
                break
        else:
            write_to_csv(data)
            save_last_page(page_number)
        page_number += 1
        
    scrape_servo_city_servo()

# Write CSV header if the file does not exist
if not os.path.exists(CSV_FILE):
    with open(CSV_FILE, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(["Company", "Model", "Torque (kg.cm)", "Speed (sec/60°)", "Weight (g)", "Price ($)", "Link"])

# Set to store unique servo names to avoid duplicates
initialize_unique_servos()
# Start scraping
scrape_all_pages()
print("Scraping completed. Data saved to", CSV_FILE)