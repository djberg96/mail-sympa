#!/usr/bin/env python3
"""
Mock Sympa SOAP Server for testing mail-sympa Ruby library
This provides basic SOAP endpoints that the Ruby library expects
"""

from flask import Flask, request, Response
from spyne import Application, rpc, ServiceBase, Unicode, Boolean, Array, ComplexModel
from spyne.protocol.soap import Soap11
from spyne.server.wsgi import WsgiApplication
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Mock data storage
class MockSympaData:
    def __init__(self):
        self.users = {}
        self.lists = ['testlist', 'partners']
        self.sessions = {}
        self.subscribers = {
            'testlist': ['test@example.com', 'user@example.com'],
            'partners': []
        }

    def authenticate(self, email, password):
        # Accept postmaster@localhost with any password for testing
        if email == 'postmaster@localhost':
            session_id = f"session_{email}"
            self.sessions[session_id] = email
            return session_id
        return None

    def is_authenticated(self, session_id):
        return session_id in self.sessions

# Global data store
mock_data = MockSympaData()

# Complex types for SOAP responses
class ListInfo(ComplexModel):
    listname = Unicode
    subject = Unicode
    status = Unicode

class SympaService(ServiceBase):

    @rpc(Unicode, Unicode, _returns=Unicode)
    def login(ctx, email, password):
        """Login to Sympa and return session cookie"""
        logger.info(f"Login attempt: {email}")
        session = mock_data.authenticate(email, password)
        if session:
            logger.info(f"Login successful for {email}")
            return session
        else:
            logger.info(f"Login failed for {email}")
            raise Exception("Authentication failed")

    @rpc(Unicode, Unicode, _returns=Array(Unicode))
    def lists(ctx, topic=None, subtopic=None):
        """Get list of mailing lists"""
        logger.info(f"Lists request: topic={topic}, subtopic={subtopic}")
        if topic and topic not in mock_data.lists:
            return []
        return mock_data.lists

    @rpc(Unicode, _returns=ListInfo)
    def info(ctx, listname):
        """Get information about a list"""
        logger.info(f"Info request for list: {listname}")
        if listname in mock_data.lists:
            info = ListInfo()
            info.listname = listname
            info.subject = f"Test list {listname}"
            info.status = "open"
            return info
        else:
            raise Exception(f"List {listname} not found")

    @rpc(Unicode, _returns=Array(Unicode))
    def review(ctx, listname):
        """Get subscribers of a list"""
        logger.info(f"Review request for list: {listname}")
        if listname in mock_data.subscribers:
            subscribers = mock_data.subscribers[listname]
            if not subscribers:
                return ['no_subscribers']
            return subscribers
        else:
            raise Exception(f"List {listname} not found")

    @rpc(Unicode, Unicode, Unicode, Boolean, _returns=Boolean)
    def add(ctx, email, listname, name, quiet=False):
        """Add user to a list"""
        logger.info(f"Add request: {email} to {listname}")
        if listname in mock_data.subscribers:
            if email not in mock_data.subscribers[listname]:
                mock_data.subscribers[listname].append(email)
            return True
        return False

    @rpc(Unicode, Unicode, _returns=Boolean)
    def del_(ctx, email, listname):
        """Remove user from a list"""
        logger.info(f"Delete request: {email} from {listname}")
        if listname in mock_data.subscribers and email in mock_data.subscribers[listname]:
            mock_data.subscribers[listname].remove(email)
            return True
        return False

    @rpc(Unicode, Unicode, _returns=Boolean)
    def subscribe(ctx, listname, name):
        """Subscribe to a list"""
        logger.info(f"Subscribe request to {listname}")
        # For subscribe, we use the authenticated user's email
        return True

    @rpc(Unicode, _returns=Boolean)
    def signoff(ctx, listname):
        """Unsubscribe from a list"""
        logger.info(f"Signoff request from {listname}")
        return True

    @rpc(Unicode, Unicode, _returns=Boolean)
    def create_list(ctx, listname, subject):
        """Create a new list"""
        logger.info(f"Create list request: {listname}")
        if listname not in mock_data.lists:
            mock_data.lists.append(listname)
            mock_data.subscribers[listname] = []
            return True
        return False

    @rpc(Unicode, _returns=Boolean)
    def close_list(ctx, listname):
        """Close/delete a list"""
        logger.info(f"Close list request: {listname}")
        if listname in mock_data.lists:
            mock_data.lists.remove(listname)
            if listname in mock_data.subscribers:
                del mock_data.subscribers[listname]
            return True
        return False

    @rpc(Unicode, Unicode, Unicode, _returns=Boolean)
    def amI(ctx, email, listname, function):
        """Check if user has specific role on list"""
        function = function or 'subscriber'  # Default value
        logger.info(f"AmI request: {email} on {listname} as {function}")
        if function == 'subscriber':
            return email in mock_data.subscribers.get(listname, [])
        elif function in ['owner', 'editor']:
            # For testing, postmaster is always owner
            return email == 'postmaster@localhost'
        return False

# Create the SOAP application
soap_app = Application([SympaService],
                      tns='urn:sympasoap',
                      in_protocol=Soap11(validator='lxml'),
                      out_protocol=Soap11())

# Create Flask app
flask_app = Flask(__name__)

# WSDL endpoint
@flask_app.route('/sympasoap?wsdl')
@flask_app.route('/sympasoap.wsdl')
def wsdl():
    """Serve WSDL"""
    wsdl_content = """<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://schemas.xmlsoap.org/wsdl/"
             xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
             xmlns:tns="urn:sympasoap"
             targetNamespace="urn:sympasoap">
  <types/>
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
      <soap:operation soapAction="login"/>
      <input><soap:body use="literal"/></input>
      <output><soap:body use="literal"/></output>
    </operation>
  </binding>
  <service name="SympaService">
    <port name="SympaPort" binding="tns:SympaBinding">
      <soap:address location="http://localhost:8080/sympasoap"/>
    </port>
  </service>
</definitions>"""
    return Response(wsdl_content, mimetype='text/xml')

# Health check
@flask_app.route('/health')
def health():
    return {'status': 'healthy', 'service': 'mock-sympa'}

# Main SOAP endpoint
wsgi_app = WsgiApplication(soap_app)

@flask_app.route('/sympasoap', methods=['POST'])
def soap_endpoint():
    """Handle SOAP requests"""
    logger.info(f"SOAP request received: {request.method}")
    logger.info(f"Content-Type: {request.content_type}")
    logger.info(f"Body: {request.data.decode('utf-8')[:500]}...")  # Log first 500 chars

    # Create a simple SOAP response for any request
    # This is a very basic implementation for testing
    response_xml = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <loginResponse xmlns="urn:sympasoap">
      <return>test_session_cookie</return>
    </loginResponse>
  </soap:Body>
</soap:Envelope>'''

    return Response(response_xml, mimetype='text/xml')

if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 8080))
    logger.info(f"Starting Mock Sympa SOAP Server on port {port}")
    flask_app.run(host='0.0.0.0', port=port, debug=True)
