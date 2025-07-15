#!/usr/bin/env python3
"""
Simple Mock Sympa SOAP Server for testing mail-sympa Ruby library
This provides basic SOAP endpoints that the Ruby library expects
"""

from flask import Flask, request, Response
import logging
import re

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Flask app
app = Flask(__name__)

def extract_soap_method(soap_body):
    """Extract the SOAP method name from the request body"""
    # Look for method calls in the SOAP body
    method_patterns = [
        r'<(\w+).*?>',  # General method pattern
        r'<ns\d+:(\w+).*?>',  # Namespaced method pattern
        r'<soap:(\w+).*?>',  # SOAP method pattern
    ]

    for pattern in method_patterns:
        match = re.search(pattern, soap_body)
        if match:
            method = match.group(1)
            if method not in ['Envelope', 'Body', 'Header']:
                return method

    return 'unknown'

def create_soap_response(method, result):
    """Create a SOAP response"""
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sym="urn:sympasoap">
  <soap:Body>
    <sym:{method}Response>
      <return>{result}</return>
    </sym:{method}Response>
  </soap:Body>
</soap:Envelope>'''

def create_soap_fault(fault_string):
    """Create a SOAP fault response"""
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>Client</faultcode>
      <faultstring>{fault_string}</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>'''

@app.route('/sympasoap', methods=['GET'])
def wsdl():
    """Serve a simple WSDL"""
    wsdl_content = '''<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://schemas.xmlsoap.org/wsdl/"
             xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
             xmlns:tns="urn:sympasoap"
             targetNamespace="urn:sympasoap"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">

  <types>
    <xsd:schema targetNamespace="urn:sympasoap">
      <xsd:element name="login" type="xsd:string"/>
      <xsd:element name="loginResponse" type="xsd:string"/>
    </xsd:schema>
  </types>

  <message name="loginRequest">
    <part name="email" type="xsd:string"/>
    <part name="password" type="xsd:string"/>
  </message>

  <message name="loginResponse">
    <part name="return" type="xsd:string"/>
  </message>

  <portType name="SympaPortType">
    <operation name="login">
      <input message="tns:loginRequest"/>
      <output message="tns:loginResponse"/>
    </operation>
  </portType>

  <binding name="SympaBinding" type="tns:SympaPortType">
    <soap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http"/>
    <operation name="login">
      <soap:operation soapAction="urn:sympasoap#login"/>
      <input><soap:body use="literal" namespace="urn:sympasoap"/></input>
      <output><soap:body use="literal" namespace="urn:sympasoap"/></output>
    </operation>
  </binding>

  <service name="SympaService">
    <port name="SympaPort" binding="tns:SympaBinding">
      <soap:address location="http://localhost:8080/sympasoap"/>
    </port>
  </service>

</definitions>'''
    return Response(wsdl_content, mimetype='text/xml')

@app.route('/sympasoap', methods=['POST'])
def soap_endpoint():
    """Handle SOAP requests"""
    try:
        soap_body = request.data.decode('utf-8')
        logger.info(f"SOAP request received: {soap_body[:500]}...")

        method = extract_soap_method(soap_body)
        logger.info(f"Extracted method: {method}")

        # Handle different SOAP methods
        if method == 'login':
            # Extract email from request
            email_match = re.search(r'<email[^>]*>([^<]+)</email>', soap_body)
            email = email_match.group(1) if email_match else 'unknown@example.com'
            logger.info(f"Login request for: {email}")

            # Return a mock session cookie
            response = create_soap_response('login', 'mock_session_12345')

        elif method == 'lists':
            logger.info("Lists request")
            response = create_soap_response('lists', ['testlist', 'partners'])

        elif method == 'info':
            list_match = re.search(r'<list[^>]*>([^<]+)</list>', soap_body)
            list_name = list_match.group(1) if list_match else 'unknown'
            logger.info(f"Info request for list: {list_name}")
            response = create_soap_response('info', f'List info for {list_name}')

        elif method == 'add':
            email_match = re.search(r'<email[^>]*>([^<]+)</email>', soap_body)
            list_match = re.search(r'<list[^>]*>([^<]+)</list>', soap_body)
            email = email_match.group(1) if email_match else 'unknown'
            list_name = list_match.group(1) if list_match else 'unknown'
            logger.info(f"Add request: {email} to {list_name}")
            response = create_soap_response('add', 'true')

        elif method == 'del':
            email_match = re.search(r'<email[^>]*>([^<]+)</email>', soap_body)
            list_match = re.search(r'<list[^>]*>([^<]+)</list>', soap_body)
            email = email_match.group(1) if email_match else 'unknown'
            list_name = list_match.group(1) if list_match else 'unknown'
            logger.info(f"Delete request: {email} from {list_name}")
            response = create_soap_response('del', 'true')

        elif method == 'review':
            list_match = re.search(r'<list[^>]*>([^<]+)</list>', soap_body)
            list_name = list_match.group(1) if list_match else 'unknown'
            logger.info(f"Review request for list: {list_name}")
            response = create_soap_response('review', ['test@example.com', 'user@example.com'])

        elif method == 'which':
            email_match = re.search(r'<email[^>]*>([^<]+)</email>', soap_body)
            email = email_match.group(1) if email_match else 'unknown'
            logger.info(f"Which request for: {email}")
            response = create_soap_response('which', ['testlist'])

        else:
            logger.warning(f"Unknown method: {method}")
            response = create_soap_fault(f"Unknown method: {method}")

        logger.info(f"Sending response: {response[:300]}...")
        return Response(response, mimetype='text/xml')

    except Exception as e:
        logger.error(f"Error processing SOAP request: {e}")
        response = create_soap_fault(f"Server error: {str(e)}")
        return Response(response, mimetype='text/xml')

if __name__ == '__main__':
    logger.info("Starting Simple Mock Sympa SOAP Server on port 8080")
    app.run(host='0.0.0.0', port=8080, debug=True)
