control 'Maven Image Build' do
  impact 'critical'
  title 'Container image has been built via Maven'
  desc 'A Docker container has been built using the Maven spring-boot:build-image phase'

  describe docker.images.where { repository == 'rest-service-complete' && tag == '0.0.1-SNAPSHOT' } do
    it { should exist }
  end
end

control 'Cassandra Running' do
  impact 'critical'
  title 'Cassandra Docker instance is running'
  desc 'A Cassandra instance is running and accessible'

  describe docker.images.where { repository == 'cassandra' && tag == '4.0.4' } do
    it { should exist }
  end
  describe docker.containers.where { names == 'cassandra-lab' && image == 'cassandra:4.0.4' } do
    its('status') { should match [/Up/] }
  end
  cql = cassandradb_session(user: 'cassandra', password: 'cassandra', host: 'cassandra-lab', port: 9042)
  describe cql.query("SELECT cluster_name FROM system.local") do
    its('output') { should match /Test Cluster/ }
  end
end

control 'Maven Container' do
  impact 'critical'
  title 'Maven Spring Boot Container running'
  desc 'The Spring Boot Container built with the Maven phase is running'

  describe docker.containers.where { names == 'spring-boot-lab' && image == 'rest-service-complete:0.0.1-SNAPSHOT' && ports =~ /0.0.0.0:8080/ } do
    its('status') { should match [/Up/] }
  end
  describe http('http://spring-boot-lab:8080/') do
    its('status') { should eq 404 }
  end
end

control 'Maven Container Replicas' do
  impact 'critical'
  title 'Maven Spring Boot Container Replicas running'
  desc 'Four more Spring Boot Containers built with the Maven phase are running'

  describe docker.containers.where { names == 'spring-boot-lab-2' && image == 'rest-service-complete:0.0.1-SNAPSHOT' && ports =~ /0.0.0.0:8081/ } do
    its('status') { should match [/Up/] }
  end
  describe http('http://spring-boot-lab-2:8080/') do
    its('status') { should eq 404 }
  end
  describe docker.containers.where { names == 'spring-boot-lab-3' && image == 'rest-service-complete:0.0.1-SNAPSHOT' && ports =~ /0.0.0.0:8082/ } do
    its('status') { should match [/Up/] }
  end
  describe http('http://spring-boot-lab-3:8080/') do
    its('status') { should eq 404 }
  end
  describe docker.containers.where { names == 'spring-boot-lab-4' && image == 'rest-service-complete:0.0.1-SNAPSHOT' && ports =~ /0.0.0.0:8083/ } do
    its('status') { should match [/Up/] }
  end
  describe http('http://spring-boot-lab-4:8080/') do
    its('status') { should eq 404 }
  end
  describe docker.containers.where { names == 'spring-boot-lab-5' && image == 'rest-service-complete:0.0.1-SNAPSHOT' && ports =~ /0.0.0.0:8084/ } do
    its('status') { should match [/Up/] }
  end
  describe http('http://spring-boot-lab-5:8080/') do
    its('status') { should eq 404 }
  end
end

control 'Dockerfile Image Build' do
  impact 'critical'
  title 'Container image has been built via Dockerfile'
  desc 'A Docker container has been built using the Dockerfile'

  describe docker.images.where { repository == 'spring-boot-lab-build' && tag == 'latest' } do
    it { should exist }
  end
  describe docker.images.where { repository == 'eclipse-temurin' && tag == '11-jre' } do
    it { should exist }
  end
end

control 'Dockerfile Build Container' do
  impact 'critical'
  title 'Custom Dockerfile Container running'
  desc 'The Spring Boot Container built with the Dockerfile'

  describe docker.containers.where { names == 'spring-boot-lab-6' && image == 'spring-boot-lab-build' && ports =~ /0.0.0.0:8085/ } do
    its('status') { should match [/Up/] }
  end
  describe http('http://spring-boot-lab-6:8080/') do
    its('status') { should eq 404 }
  end
end


