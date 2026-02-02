# Debug Guide for Doctor Report & Lab Report Submission

## Complete Debug Flow

When you submit a doctor or lab report with an image, here's what debug messages you should see in the Flutter console:

### 1. Image Selection (`_selectFromCamera` or gallery)
```
✅ Image captured and saved
📸 Image path: /path/to/images/proof_image_TIMESTAMP.jpg
```

### 2. Arguments Loading (`_loadArguments`)
```
🔍 _loadArguments DEBUG:
   isFromDoctorReport: true/false
   isDropPointReport: true/false
   reportText: "with selected option"
   tourId: "tour-id-value"
   doctorId: "doctor-id-value"
```

### 3. Submit Started (`_submitImage`)
```
🚀 _submitImage START - isFromDoctorReport: true/false, isDropPointReport: true/false
   reportText: "selected option"
   image path: /path/to/images/proof_image_TIMESTAMP.jpg
📍 Got driverId: 12345
```

### 4. Doctor Report Routing (`_submitDoctorImage`)
```
🔍 _submitDoctorImage called - reportText: "without barcode" (isEmpty: false)
📤 Routing to _submitProblemReport...
```

### 5. Problem Report Submission (`_submitProblemReport` - Doctor)
```
📤 Doctor Report Data:
   driverId: 12345
   doctorId: "doctor-id"
   tourId: "tour-id"
   text: "report option text"
   image path: /path/to/images/proof_image_TIMESTAMP.jpg

📸 Doctor report image file added: /path/to/images/proof_image_TIMESTAMP.jpg
📋 Doctor Report Request fields: {driverId: 12345, doctorId: doctor-id, tourId: tour-id, text: report text}
📁 Doctor Report Request files count: 1

📤 Doctor Report Response Status: 200
📤 Doctor Report Response Body: {"success": true, "message": "..."}
✅ Problem report submitted successfully
```

### 6. Lab Report Submission (`_submitLabProblemReport` - Drop Point)
```
📤 Lab Report Data:
   driverId: 12345
   text: "Drop point location issue"
   image path: /path/to/images/proof_image_TIMESTAMP.jpg

📸 Lab report image file added: /path/to/images/proof_image_TIMESTAMP.jpg
📋 Lab Report Request fields: {driverId: 12345, text: Drop point location issue}
📁 Lab Report Request files count: 1

📤 Lab Problem Report Response Status: 200
📤 Lab Problem Report Response Body: {"success": true, "message": "..."}
✅ Lab problem report submitted successfully
```

## What to Check

### If you see no debug output:
- Check if the Submit button is enabled (image must be selected)
- Make sure you're actually pressing the Submit button

### If debug output stops after "🚀 _submitImage START":
- Image upload to server might be failing
- reportText might be empty
- Error might be in _submitDoctorImage routing

### If debug output stops after "📍 Got driverId":
- Submission method might not be called
- Check isFromDoctorReport and isDropPointReport values

### If you see "📸 Doctor report image file added" but no response:
- Network request might be hanging
- Server might be down
- File might be too large

### If you see response status other than 200/201:
- Server returned an error
- Check the response body for error message

## How to Run with Debugging

1. Open Flutter console/terminal
2. Run: `flutter run`
3. Perform these steps in the app:
   - Go to a tour with doctors
   - Click on a doctor → Report button
   - Select a report option (e.g., "without barcode")
   - Click Next
   - Take a photo with camera or select from gallery
   - Click Submit
4. Look at the Flutter console for the debug messages above
5. Copy the complete console output and share it

## API Endpoints Being Used

- **Doctor Problem Report**: `POST http://5.189.172.20:5000/api/problemReportDr`
  - Fields: driverId, doctorId, tourId, text, image (multipart file)
  
- **Lab Problem Report**: `POST http://5.189.172.20:5000/api/problemReportLab`
  - Fields: driverId, text, image (multipart file)

## Error Messages to Watch For

- `❌ Error submitting problem report: ...` - Exception occurred
- `⚠️ Doctor report image file does not exist` - Image file path is invalid
- `⚠️ No image path provided for doctor report` - Image was not selected
- `⚠️ Problem report submission failed: [status code]` - Server returned error status

---

**Next Step**: Please run the app, perform a doctor/lab report submission with an image, and share the complete console output (especially all the messages starting with 📤, 🚀, 📸, 📋, etc.)
