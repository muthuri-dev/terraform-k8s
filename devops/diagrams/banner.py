from diagrams import Diagram, Cluster, Edge
from diagrams.elastic.elasticsearch import Elasticsearch, Kibana
from diagrams.onprem.aggregator import Fluentd
from diagrams.onprem.monitoring import Grafana
from diagrams.onprem.database import PostgreSQL

with Diagram("EFK + Grafana + PostgreSQL Stack", show=False, direction="LR"):
    
    with Cluster("Logging Stack"):
        fluentd = Fluentd("Fluentd")
        elastic = Elasticsearch("Elasticsearch")
        kibana = Kibana("Kibana")
        
        fluentd >> Edge(label="log data") >> elastic
        elastic >> Edge(label="visualize logs") >> kibana
    
    with Cluster("Monitoring"):
        grafana = Grafana("Grafana")
        grafana >> Edge(label="datasource") >> elastic

    with Cluster("Database"):
        postgres = PostgreSQL("PostgreSQL")
        postgres >> Edge(label="logs") >> fluentd
        postgres >> Edge(label="metrics") >> grafana
