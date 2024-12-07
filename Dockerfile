# Use the official Tomcat image as the base
FROM tomcat:latest

# Set the working directory to /usr/local/tomcat
WORKDIR /usr/local/tomcat

# Copy the WAR file to the webapps directory
ADD target/addressbook.war /usr/local/tomcat/webapps/

# Expose the port
EXPOSE 8080

# Set the environment variables
ENV JAVA_OPTS="-Xms512m -Xmx1024m"
ENV CATALINA_OPTS="-Djava.net.preferIPv4Stack=true"

# Set the default command to run when the container starts
CMD ["catalina.sh", "run"]
