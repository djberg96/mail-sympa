FROM debian:bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add Sympa repository
RUN wget -q -O - https://sympa-community.github.io/gpg/sympa-community.asc | apt-key add - \
    && echo "deb https://sympa-community.github.io/debian/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/sympa.list

# Install Sympa and dependencies
RUN apt-get update && apt-get install -y \
    sympa \
    apache2 \
    libapache2-mod-fcgid \
    postgresql-client \
    postfix \
    postfix-pgsql \
    libdbi-perl \
    libdbd-pg-perl \
    libsoap-lite-perl \
    libxml-libxml-perl \
    libcrypt-ciphersaber-perl \
    libmime-lite-html-perl \
    libmime-charset-perl \
    libmail-dkim-perl \
    libunicode-linebreak-perl \
    libtemplate-perl \
    libdatetime-perl \
    libdatetime-timezone-perl \
    libdatetime-format-mail-perl \
    libarchive-zip-perl \
    libio-stringy-perl \
    libmime-encwords-perl \
    libproc-processtable-perl \
    libterm-progressbar-perl \
    cpanminus \
    && rm -rf /var/lib/apt/lists/*

# Install additional Perl modules for SOAP support
RUN cpanm --notest SOAP::Lite

# Copy configuration files
COPY docker/sympa/config/ /etc/sympa/
COPY docker/sympa/apache-config/ /etc/apache2/sites-available/

# Set up Apache
RUN a2enmod fcgid rewrite ssl \
    && a2dissite 000-default \
    && a2ensite sympa

# Create sympa user and directories
RUN useradd -r -m -d /var/lib/sympa -s /bin/bash sympa \
    && mkdir -p /var/lib/sympa/list_data \
    && mkdir -p /var/spool/sympa \
    && mkdir -p /var/log/sympa \
    && chown -R sympa:sympa /var/lib/sympa /var/spool/sympa /var/log/sympa

# Copy startup script
COPY docker/sympa/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Set up postfix for local delivery
RUN echo "relayhost =" >> /etc/postfix/main.cf \
    && echo "inet_interfaces = all" >> /etc/postfix/main.cf \
    && echo "mydestination = localhost, localhost.localdomain" >> /etc/postfix/main.cf

EXPOSE 80 25 587

CMD ["/usr/local/bin/start.sh"]
