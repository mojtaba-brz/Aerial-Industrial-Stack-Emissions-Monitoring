import os
import time
import numpy as np

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver import ActionChains as AC

# Functions ======================================================
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

def take_driver_to_webpage_with_retries(driver: webdriver, url : str):
    while True:
        try:
            driver.get(url)
            break
        except:
            print(f"retry for : {url}")
            time.sleep(3)

# Constants ======================================================
THIS_FILE_ADDRESS, _ = os.path.split(__file__)
FILE_POST_FIX = "-TMotorTestData.csv"
MOTORS_SPECS_FILE = "MotorsSpecs.csv"
URL_AND_NAME_TUPLE = (("https://store.tmotor.com/product/u3-motor-u-power.html", "U3"),
                      ("https://store.tmotor.com/product/u-power-u5.html", "U5"),
                      ("https://store.tmotor.com/product/tmotor-u7-v2-motor-u-power.html", "U7"),
                      ("https://store.tmotor.com/product/u11-v2-motor-u-power.html", "U11-Ⅱ"),
                      ("https://store.tmotor.com/product/u13-v2-kv65-motor-u-power.html", "U13 Ⅱ U13Ⅱ"),
                      ("https://store.tmotor.com/product/u15-v2-motor-u-power-kv80.html", "U15Ⅱ"),
                      ("https://store.tmotor.com/product/u8-lite-kv100-u-efficiency.html", "U8II lite"),
                      ("https://store.tmotor.com/product/u8lite-l-kv110-u-efficiency.html", "U8lite L"),
                      ("https://store.tmotor.com/product/u8-v2-u-efficiency-kv85.html", "U8II"),
                      ("https://store.tmotor.com/product/u8-v2-lite-u-efficiency.html", "U8II lite"),
                      ("https://store.tmotor.com/product/u8-2-pro-u-efficiency.html", "U8II Pro"),
                      ("https://store.tmotor.com/product/u10-2-u-efficiency.html", "U10II"),
                      ("https://store.tmotor.com/product/u12-v2-kv60-u-efficiency.html", "U12 II U12Ⅱ"),
                      ("https://store.tmotor.com/product/P60-pin-kv170-p-type.html", "P60"),
                      ("https://store.tmotor.com/product/P80-v3-without-pin-kv100-p-type.html", "P80 ΙΙΙ"),
                      ("https://store.tmotor.com/product/antigravity-mn2806-evo-motor.html", "MN2806 EVO"),
                      ("https://store.tmotor.com/product/mn2806-motor-antigravity-type.html", "MN2806"),
                      ("https://store.tmotor.com/product/mn4004-kv300-motor-antigravity-type.html", "MN4004"),
                      ("https://store.tmotor.com/product/mn4006-kv380-motor-antigravity-type.html", "MN4006"),
                      ("https://store.tmotor.com/product/mn4006-EVO-kv380-motor-antigravity-type.html", "MN4006 EVO"),
                      ("https://store.tmotor.com/product/mn5006-kv300-motor-antigravity-type.html", "MN5006"),
                      ("https://store.tmotor.com/product/mn5008-kv170-motor-antigravity-type.html", "MN5008"),
                      ("https://store.tmotor.com/product/mn6007-kv160-motor-antigravity-type.html", "MN6007"),
                      ("https://store.tmotor.com/product/mn6007-v2-motor-antigravity-type.html", "MN6007II"),
                      ("https://store.tmotor.com/product/mn7005-kv115-motor-antigravity-type.html", "MN7005"),
                      ("https://store.tmotor.com/product/mn8012-motor-antigravity-type.html", "MN8012"),
                      ("https://store.tmotor.com/product/mn8014-motor-antigravity-type.html", "MN8014"),
                      ("https://store.tmotor.com/product/mn8017-motor-antigravity-type.html", "MN8017"),
                      ("https://store.tmotor.com/product/mn1005-v2-motor-antigravity-type.html", "MN1005 V2.0"),
                      ("https://store.tmotor.com/product/mn4116-motor-navigator-type.html", "MN4116"),
                      ("https://store.tmotor.com/product/mn4112-motor-navigator-type.html", "MN4112"),
                      ("https://store.tmotor.com/product/mn4110-motor-navigator-type.html", "MN4110"),
                      ("https://store.tmotor.com/product/mn501-s-kv240-motor-navigator-type.html", "MN501"),
                      ("https://store.tmotor.com/product/mn505-s-kv320-motor-navigator-type.html", "MN505"),
                      ("https://store.tmotor.com/product/mn601-s-kv170-motor-navigator-type.html", "MN601"),
                      ("https://store.tmotor.com/product/mn605-s-kv170-motor-navigator-type.html", "MN605"),
                      ("https://store.tmotor.com/product/mn701-s-kv135-motor-navigator-type.html", "MN701"),
                      ("https://store.tmotor.com/product/mn705-s-kv125-motor-navigator-type.html", "MN705"),
                      ("https://store.tmotor.com/product/mn801-s-kv120-motor-navigator-type.html", "MN801"),
                      ("https://store.tmotor.com/product/mn805-s-kv120-motor-navigator-type.html", "MN805"),
                      ("https://store.tmotor.com/product/mn1010-kv90-motor-navigator-type.html", "MN1010"),
                      ("https://store.tmotor.com/product/mn1015-motor-navigator-type.html", "MN1015"),
                      ("https://store.tmotor.com/product/mn1018-motor-navigator-type.html", "MN1018"),
                      ("https://store.tmotor.com/product/mn2212-v2-motor-navigator-type.html", "MN2212"),
                      ("https://store.tmotor.com/product/mn3110-motor-navigator-type.html", "MN3110"),
                      ("https://store.tmotor.com/product/mn3508-motor-navigator-type.html", "MN3508"),
                      ("https://store.tmotor.com/product/mn3510-motor-navigator-type.html", "MN3510"),
                      ("https://store.tmotor.com/product/mn3515-motor-navigator-type.html", "MN3515"),
                      ("https://store.tmotor.com/product/mn3520-motor-navigator-type.html", "MN3520"),
                      ("https://store.tmotor.com/product/mn4010-kv370-motor-navigator-type.html", "MN4010"),
                      ("https://store.tmotor.com/product/mn4012-kv340-motor-navigator-type.html", "MN4012"),
                      ("https://store.tmotor.com/product/mn4014-kv330-motor-navigator-type.html", "MN4014"),
                      ("https://store.tmotor.com/product/mn5208-motor-navigator-type.html", "MN5208"),
                      ("https://store.tmotor.com/product/mn5212-kv340-motor-navigator-type.html", "MN5212"))

# ====== ==========================================================================================================================================
# Script ==========================================================================================================================================
# ====== ==========================================================================================================================================
all_motors_are_not_collected = True
while all_motors_are_not_collected:
    all_motors_are_not_collected = False
    all_files_in_this_flies_dir = os.listdir(f"{THIS_FILE_ADDRESS}\\..")

    all_motors_in_motor_specs = []
    with open(f"{THIS_FILE_ADDRESS}\\..\\{MOTORS_SPECS_FILE}", 'r', encoding="utf-8") as f:
        lines = f.read().split('\n')[1:]
        for line in lines:
            all_motors_in_motor_specs += [line.split(',')[0]]
            
    for url_and_name in URL_AND_NAME_TUPLE:
        url = url_and_name[0]
        motor_name = url_and_name[1]
        if f"{motor_name}{FILE_POST_FIX}" in all_files_in_this_flies_dir and motor_name in all_motors_in_motor_specs:
            continue
        all_motors_are_not_collected = True
        print(f"=========================================================================================================")
        print(f"Motor Name: {motor_name}")
        print(f"=========================================================================================================")
        opts = webdriver.chrome.options.Options()
        # opts.page_load_strategy = 'none'
        # opts.page_load_strategy = 'eager'
        opts.headless = False
        opts.add_argument('--headless')
        driver = webdriver.Chrome(opts)
        driver_wait = WebDriverWait(driver, 60)
        take_driver_to_webpage_with_retries(driver, url)
        driver.maximize_window()
        time.sleep(2) # Interact more naturally

        # To close an Ad banner if exists
        try:
            driver.find_element(By.XPATH, "//div[@class='close']").click()
        except:
            pass
            
        specs_elem = driver_wait.until(EC.presence_of_element_located((By.XPATH, "//li[@class='detail-nav-item']")))
        AC(driver).scroll_to_element(specs_elem).perform()
        driver_wait.until(EC.element_to_be_clickable((By.XPATH, "//li[@class='detail-nav-item']"))).click()
        
        # Extracting Test Data ================================================================================================== 
        tables = driver_wait.until(EC.presence_of_all_elements_located((By.XPATH, "//table")))

        test_data_table = tables[-1]
        test_data_csv_text = ""

        test_data_table_headers = test_data_table.find_element(By.XPATH, "thead").find_element(By.XPATH, "tr").find_elements(By.XPATH, "td")
        n_cols = len(test_data_table_headers)
        for header in test_data_table_headers:
            header_text = " ".join(header.text.split("\n"))
            test_data_csv_text += header_text + ","
        test_data_csv_text = test_data_csv_text[:-1] + test_data_csv_text[-1].replace(",", "\n")

        test_data_table_body_rows = test_data_table.find_element(By.XPATH, "tbody").find_elements(By.XPATH, "tr")
        repeated_row_values = n_cols * [[]]
        for row in test_data_table_body_rows:
            cells = row.find_elements(By.XPATH, "td")
            if(len(cells) < 3):
                continue
            cell_idx = 0
            for i in range(n_cols):
                if repeated_row_values[i]:
                    test_data_csv_text += repeated_row_values[i].pop() + ","
                else:
                    cell_text = " ".join(cells[cell_idx].text.split("\n"))
                    if cells[cell_idx].get_attribute("colspan"): # Only colspan = 2 is supported
                        if cells[cell_idx].get_attribute("rowspan"):
                            row_span = robust_int64(cells[cell_idx].get_attribute("rowspan"))
                            repeated_row_values[i]   = (row_span - 1) * [""]
                            test_data_csv_text += ","
                            repeated_row_values[i+1] = (row_span - 1) * [cell_text]
                            test_data_csv_text += cell_text + ","
                            break
                            
                    elif cells[cell_idx].get_attribute("rowspan"):
                        row_span = robust_int64(cells[cell_idx].get_attribute("rowspan"))
                        repeated_row_values[i] = (row_span - 1) * [cell_text]
                        
                    test_data_csv_text += cell_text + ","
                    
                    cell_idx += 1
                    
            test_data_csv_text = test_data_csv_text[:-1] + test_data_csv_text[-1].replace(",", "\n")
        
        # Extracting Motor Specs ================================================================================================== 
        company_name = "T-Motor"
        motor_price  = robust_float64(driver.find_element(By.XPATH, "//span[@class='discount-price']").text.split("$")[-1])
        motor_specs_tables = driver.find_elements(By.XPATH, "//table[@class='spaced-table']")
        for table in motor_specs_tables:
            k_v         = ""
            r_in        = ""
            weight      = ""
            min_volt    = ""
            max_volt    = ""
            max_power   = ""
            max_current = ""
            for row in table.find_elements(By.XPATH, "tbody/tr"):
                cells = row.find_elements(By.XPATH, "td")
                if len(cells) < 4:
                    continue
                
                if cells[0].text == "Test Item" or cells[0].text == "KV" or "KV" in cells[0].text:
                    k_v = cells[1].text.split("KV")[-1]
                if cells[2].text == "Test Item" or cells[2].text == "KV" or "KV" in cells[2].text:
                    k_v = cells[3].text.split("KV")[-1]
                
                if cells[0].text.replace(" ", "").replace("\n", "").lower() == "internalresistance":
                    r_in = cells[1].text.split("m")[0].split("±")[0]
                    if "-" in r_in:
                        r_in = np.mean(robust_float64(r_in.split("-")))
                        r_in = f"{r_in:0.2f}" 
                if cells[2].text.replace(" ", "").replace("\n", "").lower() == "internalresistance":
                    r_in = cells[3].text.split("m")[0].split("±")[0]
                    if "-" in r_in:
                        r_in = np.mean(robust_float64(r_in.split("-")))
                        r_in = f"{r_in:0.2f}" 
                
                if cells[0].text.replace(" ", "").replace("\n", "").lower() in ["weightincludingcables", "motorweight(incl.cable)", "weight(incl.cable)", "motorweight(indl.cable)", "motorweight(g)"]:
                    weight = cells[1].text.split("g")[0]
                if cells[2].text.replace(" ", "").replace("\n", "").lower() in ["weightincludingcables", "motorweight(incl.cable)", "weight(incl.cable)", "motorweight(indl.cable)", "motorweight(g)"]:
                    weight = cells[3].text.split("g")[0]
                    if "k" in weight.lower():
                        weight = robust_float64(weight.lower().split("k")[0]) * 1000
                
                if cells[0].text.replace(" ", "").replace("\n", "").lower() in ["no.ofcells(lipo)", "ratedvoltage(lipo)"]:
                    temp = cells[1].text.split("S")[0]
                    if "-" in temp:
                        temp = temp.split("-")
                        min_volt = f"{robust_int64(temp[0]) * 2.7:0.2f}"
                        max_volt = f"{robust_int64(temp[1]) * 4.2:0.2f}" 
                    else:
                        min_volt = f"{robust_int64(temp) * 2.7:0.2f}"
                        max_volt = f"{robust_int64(temp) * 4.2:0.2f}" 
                if cells[2].text.replace(" ", "").replace("\n", "").lower() in ["no.ofcells(lipo)", "ratedvoltage(lipo)"]:
                    temp = cells[3].text.split("S")[0]
                    if "-" in temp:
                        temp = temp.split("-")
                        min_volt = f"{robust_int64(temp[0]) * 2.7:0.2f}"
                        max_volt = f"{robust_int64(temp[1]) * 4.2:0.2f}" 
                    else:
                        min_volt = f"{robust_int64(temp) * 2.7:0.2f}"
                        max_volt = f"{robust_int64(temp) * 4.2:0.2f}" 
                
                if cells[0].text.replace(" ", "").replace("\n", "").lower() in ["maxcontinuouscurrent180s", "peakcurrent(180s)"]:
                    max_current = cells[1].text.split("A")[0]
                if cells[2].text.replace(" ", "").replace("\n", "").lower() in ["maxcontinuouscurrent180s", "peakcurrent(180s)"]:
                    max_current = cells[3].text.split("A")[0]
                
                if cells[0].text.replace(" ", "").replace("\n", "").lower() in ["maxcontinuouspower180s", "max.power", "max.power(180s)"]:
                    max_power = cells[1].text.split("W")[0]
                if cells[2].text.replace(" ", "").replace("\n", "").lower() in ["maxcontinuouspower180s", "max.power", "max.power(180s)"]:
                    max_power = cells[3].text.split("W")[0]
                    
            if weight == "":
                continue
            if k_v == "":
                k_v = driver.find_element(By.XPATH, "//h1[@class='title']").text.split("KV")[-1]        
            with open(f"{THIS_FILE_ADDRESS}\\..\\{MOTORS_SPECS_FILE}", 'a', encoding="utf-8") as f:
                f.write(f"{motor_name},{company_name},{motor_price},{k_v},{r_in},{weight},{min_volt},{max_volt},{max_current},{max_power},{url},\n")
            
        with open(f"{THIS_FILE_ADDRESS}\\..\\{motor_name}{FILE_POST_FIX}", 'w', encoding="utf-8") as f:
            f.write(test_data_csv_text)
        
        driver.close()