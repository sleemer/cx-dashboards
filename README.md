# Customer Experience Dashboards as Code

This repository provides examples of Customer Experience (CX) dashboards built using the [Grafonnet library](https://github.com/grafana/grafonnet/tree/main) and the [Jsonnet](https://jsonnet.org/) programming language.


## Introduction

Dashboards help engineers monitor systems by summarizing metrics, traces, and logs. CX dashboards take this further by focusing on user outcomes, ensuring services consistently deliver value.

Unlike traditional system monitoring, CX dashboards shift the focus from internal system metrics to user experience, allowing engineers to monitor and improve user satisfaction directly. They prioritize tracking the availability and performance of key features, ensuring users can successfully complete their tasks.

If you're building multiple CX dashboards across different services, maintaining consistency and manageability can be challenging. A great solution is to define dashboards as code. This repository demonstrates a CX dashboard built for an ASP.NET Core API, but the approach applies to any system, including complex systems with multiple services and background jobs.

The `src` directory contains:
- Two example CX dashboards. The first is a high-level dashboard with aggregated metrics. The second introduces an additional **customer** dimension. This approach helps narrow down impacted users while keeping metrics cardinality manageable. It’s not always feasible, but in this example, we assume `some_service` provides an API for other businesses (customers), allowing user data to be aggregated at the customer level. If your service is used directly by end users, with thousands or even millions of unique users, other dimensions - such as availability zones, clusters, or data centers - may be more suitable.
- Reusable components in the `lib` subfolder. If you plan to reuse these components, consider moving them to a separate repository, similar to how this project references the Grafonnet library. The components are organized around **graphs**.

A **graph** in this context is a wrapper for:
- **Grafana panels** – UI components displaying data.
- **Queries** – Fetching metrics from data sources.
- **Links** – URLs for zooming in/out, accessing external resources, and aiding root cause analysis.

A graph provides two APIs:

- **Builder API** – Configures the graph to visualize CX metrics of the Service API.
- **Grafana panels** – Visualizes the CX metrics.

Here’s an example of how the configuration code looks:

```jsonnet
local allAPIs = graph.new('All APIs')
  + graph.textOptions.withDescription(
  |||
    SomeService has two SLOs that apply to overall API availability
    - The SLO is breached if availability drops below 99% for more than 5 minutes

    For API latency, we have SLOs that apply to avg and p99 latencies
    - Average latency SLO is breached if average latencies exceed 100ms for 5 minutes
    - p99 latency SLO is breached if p99 latency exceeds 500ms for 15 minutes
  |||)
  + graph.sloOptions.withAvailability(99)
  + graph.sloOptions.withLatencyMs('avg', 100)
  + graph.sloOptions.withLatencyMs('p99', 500);
```
After configuring it, here's how it is added to the dashboard:

```jsonnet
  allAPIs.apiNotes
  + panelOptions.withGridPos(h = 10, w = 6, x = 0, y = 6),
  allAPIs.timeSeries.availability
  + panelOptions.withGridPos(h = 10, w = 6, x = 6, y = 6),
  allAPIs.timeSeries.latency
  + panelOptions.withGridPos(h = 10, w = 6, x = 12, y = 6),
  allAPIs.timeSeries.requests
  + panelOptions.withGridPos(h = 10, w = 6, x = 18, y = 6),
```

For more details on CX Dashboards and their importance, check out [my article on LinkedIn](https://www.linkedin.com/pulse/building-dashboards-matter-backend-engineers-view-cx-kovalev-r3omf/).


## Getting started

In order to make it easier to get started this repo provides dev environment incapsulated inside dev container. Install the prerequisites first, clone the repo and open it in Visual Studio Code. When you open it Visual Studio Code will detect that the repo has .devcontainer and ask you if you want to open the folder in container - say yes. That will trigger initialization logic, so if you open it for the first time it will pull all images from docker hub, will build sample some_service image that will serve as a source of metrics for our CX Dashboards. Alongside a Dev container Visual Studio Code will also spin up Grafana and Prometheus and configure them. The dev container itself will have all the extensions and tools you will need to build and test dashboards, including golang, jsonnet, jsonnet-bundler and k6.

### Prerequisites

- Visual Studio Code ([download](https://code.visualstudio.com/download)) with at least the following extensions installed:
  - [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

- Docker for desktop ([download](https://www.docker.com/products/docker-desktop))
  > You can also use [PodMan](https://podman.io) as a Docker Desktop alternative.

## Running

- Open integrated terminal in Visual Studio Code and run the following command there to build and deploy the dashboards to Grafana
```bash
make publish
```

- Generate traffic for some_service using the k6 script (it will run for 5 minutes)
```bash
make traffic
```

- Open your browser and go to [http://localhost:3000/dashboards](http://localhost:3000/dashboards). If everything is set up correctly, you should see two dashboards.

  - Start with the **CX Overview dashboard** to get a high-level view of `some_service` API metrics.
  - To investigate the impact on a specific customer, select one from the **IMPACTED CUSTOMERS** table. Clicking on a customer will zoom-in to a detailed CX dashboard, displaying metrics specific to that customer.
