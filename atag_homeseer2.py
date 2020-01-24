import serial
import os

DEBUG = True
DEVICE_CODE="V" 
LOCATION="ATAG"        # room
COM_PORT=4             # (0...x) (port1 = 0)
LOG_TO_MDB_FILE = True # logs data to <homeseer_path>/data/ATAG

script_name = "ATAG"

def hextranslate(s):
        res = ""
        for i in range(len(s)/2):
                realIdx = i*2
                t = lambda x: int(x, 16) - ((int(x, 16) >> 7) * 256)
                res = res + str(t(s[realIdx:realIdx+2]))
        return res

def ReadAtagSer(ser):
   """
   ReadAtagSer
   In:
     ser
   Return:
     dict list with data
   """

   data = []

   r = ser.read(size=1000)  
   r = r.encode("hex")

   a = r.split('41 06 41 82 60')
   65 6 65 130 96 
   print(a)

   for elem in a:
         if len(elem) == 50:
           d = dict(name="",string_value="", int_value=0)

           if elem[18:20] == "34":
              d["name"]="Aanvoer Temp"
              d["int_value"]=int(hextranslate(elem[28:30]))
              d["string_value"]=hextranslate(elem[28:30])+unichr(176).encode("latin-1")+"C"
              data.append(d)
              
              d2 = d.copy()
              d2["name"]="Buiten Temp"
              d2["int_value"]=int(hextranslate(elem[34:36]))
              d2["string_value"]=hextranslate(elem[34:36])+unichr(176).encode("latin-1")+"C"
              data.append(d2)

           if elem[18:20] == "37":
              d["name"]="Druk"
              druk = hextranslate(elem[42:44])
              d["int_value"]=int(druk)
              druk = druk[0]+"."+druk[1]
              d["string_value"]=druk+" bar"
              data.append(d)

           if elem[18:20] == "38":
              d["name"]="Brander CV"
              d["int_value"]=int(hextranslate(elem[40:42]))
              d["string_value"]=hextranslate(elem[40:42])+"%"
              data.append(d)
   print(data)
   return data

def GetUsedNumbersForDeviceCode(device_code):
    """
    GetUsedNumbersForDeviceCode
    Return: 
         list with used numbers for device_code
         -1 on error
         -2 if device count changed

    """

    used_device_num = []

    en = hs.GetDeviceEnumerator()
    if en == None:
       print("ERROR "+script_name,"ERROR Get Device Enumerator")
       return -1

    while not en.Finished:
       if en.CountChanged:
          print("ERROR "+script_name,"ERROR Device Count Changed")
          return -2      
       dv = en.GetNext() 
       if dv != None:
          if dv.hc == device_code:
             used_device_num.append(int(dv.dc))
   
    return used_device_num


def GetDeviceClass_CreateIfNotExists(location, device_name, device_code):
    """
    GetDeviceClass_CreateIfNotExists
    Return: 
          DeviceClass
          -1 on error

    """
   
    dv = hs.GetDeviceEx(location+" "+device_name)
    if dv == None:
       print("Info "+script_name,"Creating device ["+device_name+"] location ["+location+"]")
       used_numbers = -2
       while used_numbers == -2:
          used_numbers = GetUsedNumbersForDeviceCode(device_code)
       if used_numbers == -1:
          return -1
       else:
          count = 1
          found = False
          while count!=99 and not found:
             if count not in used_numbers:
                found = True
             else:
                count = count+1
          if not found:
             print("ERROR "+script_name,"Can not find a free number for device code["+device_code+"][1..99]")
             return -1    

          dv = hs.NewDeviceEx(device_name)
          dv.hc=device_code
          dv.dc=count
          dv.location = location
          dv.dev_type_string="Status Only"
          dv.misc = dv.misc | 16
          hs.setdevicestatus(device_code+str(count),17)
      
    return dv

def Main():

   if DEBUG: 
      print("Debug "+script_name,"Read some ATAG Blauwe Engel 2 Data")

   # Setup COM port
   ser = serial.Serial()
   ser.port = '/dev/ttyAMA0'
   ser.baudrate = 9600
   ser.stopbits = 1
   ser.bytesize = serial.EIGHTBITS
   ser.parity = serial.PARITY_NONE
   ser.interCharTimeout = 0
   ser.timeout = 30

   if ser.isOpen() == True:
      print("ERROR "+script_name,ser.port+" already open")
      return 1

   ser.open()
   ser.setRTS(False)
   ser.setDTR(True)
   # ser.setXON(False)
   # ser.setBreak(False)
   ser.flushOutput()
   ser.flushInput()
   
   # Read ATAG data
   if DEBUG:
      print("Debug "+script_name,"reading data....")   
   ser.flushInput()
   ser.flushOutput()
   r = ReadAtagSer(ser)
   ser.close()

   if DEBUG:
      for elem in r:
         print("Debug "+script_name,"found: "+elem["name"]+"="+elem["string_value"]+" ("+str(elem["int_value"])+")")

   # Update devices
   for elem in r:
      dv = GetDeviceClass_CreateIfNotExists(LOCATION,elem["name"],DEVICE_CODE) 



   
Main()