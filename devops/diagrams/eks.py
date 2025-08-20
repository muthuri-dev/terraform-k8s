from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EKS, EC2
from diagrams.aws.network import VPC, InternetGateway, NATGateway, PublicSubnet, PrivateSubnet, ELB
from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.database import PostgreSQL
from diagrams.elastic.elasticsearch import Elasticsearch
from diagrams.generic.compute import Rack
from diagrams.generic.storage import Storage
from diagrams.k8s.compute import Pod
from diagrams.k8s.storage import PV

with Diagram("EKS Cluster with PostgreSQL, Monitoring and Logging Stack", 
             show=False, direction="TB", filename="eks_infrastructure"):
    
    # User Access
    users = Storage("External Users")
    
    # Load Balancers
    with Cluster("Load Balancers"):
        postgres_lb = ELB("PostgreSQL LB")
        grafana_lb = ELB("Grafana LB") 
        kibana_lb = ELB("Kibana LB")
    
    # VPC and Networking Components
    with Cluster("AWS VPC (10.0.0.0/16)"):
        vpc = VPC("VPC")
        igw = InternetGateway("Internet Gateway")
        
        with Cluster("Public Subnets"):
            nat_gw = NATGateway("NAT Gateway")
            public_subnet = PublicSubnet("Public Subnets\n(10.0.101.0/24)")
        
        with Cluster("Private Subnets"):
            private_subnet_1 = PrivateSubnet("Private Subnet AZ-1\n(10.0.1.0/24)")
            private_subnet_2 = PrivateSubnet("Private Subnet AZ-2\n(10.0.2.0/24)")
            private_subnet_3 = PrivateSubnet("Private Subnet AZ-3\n(10.0.3.0/24)")
    
    # EKS Cluster
    with Cluster("EKS Cluster (Kubernetes 1.27)"):
        eks_control = EKS("EKS Control Plane")
        
        with Cluster("Managed Node Group"):
            with Cluster("AZ-1"):
                node1 = EC2("t3.medium\nNode 1")
            with Cluster("AZ-2"):
                node2 = EC2("t3.medium\nNode 2")
            with Cluster("AZ-3"):
                node3 = EC2("t3.medium\nNode 3")
        
        # Database Namespace
        with Cluster("Database Namespace"):
            with Cluster("CloudNativePG Cluster (3 instances)"):
                pg_primary = PostgreSQL("PostgreSQL\nPrimary")
                pg_replica1 = PostgreSQL("PostgreSQL\nReplica 1")
                pg_replica2 = PostgreSQL("PostgreSQL\nReplica 2")
                
                # Persistent Volumes for PostgreSQL
                pv1 = PV("PV 1GB")
                pv2 = PV("PV 1GB")
                pv3 = PV("PV 1GB")
                
                pg_primary - pv1
                pg_replica1 - pv2
                pg_replica2 - pv3
        
        # Monitoring Namespace
        with Cluster("Monitoring Namespace"):
            prometheus_pod = Prometheus("Prometheus\n(10GB storage)")
            grafana_pod = Grafana("Grafana\n(5GB storage)")
            
            # Prometheus storage
            prom_pv = PV("Prometheus PV\n10GB")
            grafana_pv = PV("Grafana PV\n5GB")
            
            prometheus_pod - prom_pv
            grafana_pod - grafana_pv
        
        # Logging Namespace
        with Cluster("Logging Namespace"):
            fluentd_ds = Rack("Fluentd\nDaemonSet")
            elasticsearch_pod = Elasticsearch("Elasticsearch\nCluster")
            kibana_pod = Rack("Kibana\nInterface")
            
            # Elasticsearch storage
            es_pv = PV("Elasticsearch PV")
            elasticsearch_pod - es_pv
    
    # Network Flow Connections
    users >> Edge(color="blue", label="HTTPS") >> [grafana_lb, kibana_lb]
    users >> Edge(color="green", label="PostgreSQL") >> postgres_lb
    
    # Load balancer to services
    postgres_lb >> Edge(color="green") >> pg_primary
    grafana_lb >> Edge(color="blue") >> grafana_pod
    kibana_lb >> Edge(color="orange") >> kibana_pod
    
    # VPC Network Flow
    igw >> public_subnet >> nat_gw
    nat_gw >> [private_subnet_1, private_subnet_2, private_subnet_3]
    
    # Node placement in subnets
    private_subnet_1 >> node1
    private_subnet_2 >> node2  
    private_subnet_3 >> node3
    
    # EKS Control Plane to Nodes
    eks_control >> Edge(color="purple", label="API") >> [node1, node2, node3]
    
    # PostgreSQL Replication
    pg_primary >> Edge(style="dashed", color="green", label="streaming\nreplication") >> pg_replica1
    pg_primary >> Edge(style="dashed", color="green", label="streaming\nreplication") >> pg_replica2
    
    # Monitoring Data Flow
    [pg_primary, pg_replica1, pg_replica2] >> Edge(color="red", label="metrics") >> prometheus_pod
    [node1, node2, node3] >> Edge(color="red", label="node metrics") >> prometheus_pod
    prometheus_pod >> Edge(color="blue", label="datasource") >> grafana_pod
    
    # Logging Data Flow  
    [pg_primary, pg_replica1, pg_replica2] >> Edge(color="orange", label="logs") >> fluentd_ds
    [node1, node2, node3] >> Edge(color="orange", label="system logs") >> fluentd_ds
    fluentd_ds >> Edge(color="orange", label="forward logs") >> elasticsearch_pod
    elasticsearch_pod >> Edge(color="purple", label="query logs") >> kibana_pod
    
    # Additional monitoring connections
    grafana_pod >> Edge(style="dotted", color="gray", label="dashboard queries") >> prometheus_pod
    kibana_pod >> Edge(style="dotted", color="gray", label="log searches") >> elasticsearch_pod