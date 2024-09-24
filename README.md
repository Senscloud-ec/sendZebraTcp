# Zebra Printer PDF Generator

This project is a Flutter application that generates a PDF with dynamic data and sends it to a Zebra printer via a TCP/IP server. The data is dynamically formatted, and the PDF includes a QR code based on user-provided content.

## Features

- Generates a PDF with custom label data
- Allows users to input printer IP and port
- Supports dynamic data input through a text field
- Provides a dropdown to select the QR code format (JSON or CSV)
- Sends the generated PDF to a Zebra printer over TCP/IP
- Automatically deletes the temporary PDF file after sending

## Requirements

- Flutter SDK
- Zebra printer with TCP/IP capability
- Dependencies:
    - `pdf`: For generating the PDF
    - `zsdk`: For handling Zebra SDK functionalities
    - `path_provider`: To manage file storage

## Installation

1. Clone this repository:
    ```bash
    git clone https://github.com/your-username/zebra-printer-pdf-generator.git
    ```
2. Navigate to the project directory:
    ```bash
    cd zebra-printer-pdf-generator
    ```
3. Install the required dependencies:
    ```bash
    flutter pub get
    ```

## Usage

1. Run the application:
    ```bash
    flutter run
    ```
2. Input the Zebra printer's IP address and port number.
3. Optionally modify the label text in the provided text area.
4. Select the QR code format (JSON or CSV) from the dropdown menu.
5. Click the **Generate and Send PDF** button to create the PDF and send it to the Zebra printer.

## Dynamic Data Input

By default, the application generates a label with the following data:

```json
{
  "N° etiqueta impresión": "IMP-000002",
  "N° etiqueta extrusión": "EXT-000003",
  "Orden Prod.": "OPIMP-005",
  "Fecha": "26/07/2024",
  "Turno": "Turno 2",
  "Operador": "Pedro Sanchez",
  "Máquina": "15",
  "Tipo Producto": "Emp. Tarrina diamante",
  "Color prep.": "Transparente",
  "Peso Neto Extrusión": "130",
  "Peso Neto Impresión": "120",
  "Densidad": "Baja",
  "Cliente": "Stock"
}
