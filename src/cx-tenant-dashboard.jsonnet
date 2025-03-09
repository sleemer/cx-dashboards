local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local graph = import 'lib/graphs.libsonnet';
local variable = import 'lib/variables.libsonnet';
local link = import 'lib/links.libsonnet';
local dashboard = g.dashboard;
local row = g.panel.row;
local panelOptions = g.panel.stat.panelOptions;

local someServiceAPIsAtGlance = graph.new('SomeService APIs At A Glance')
  + graph.textOptions.withFootnotes('Note: all graphs show stats for the last 5 min')
  + graph.options.withAtAGlanceTimeWindow('5m')
  + graph.filterOptions.withCustomer('$%s' % variable.customer.name)
  + graph.sloOptions.withAvailability(100)
  + graph.sloOptions.withLatencyMs('avg', 100)
  + graph.sloOptions.withLatencyMs('p99', 300);

local allAPIs = graph.new('All APIs')
  + graph.textOptions.withDescription(
  |||
    SomeService has two SLOs that apply to overall API availability
    - The SLO is breached if availability drops below 99% for more than 5 minutes

    For API latency, we have SLOs that apply to avg and p99 latencies
    - Average latency SLO is breached if average latencies exceed 100ms for 5 minutes
    - p99 latency SLO is breached if p99 latency exceeds 500ms for 15 minutes
  |||)
  + graph.filterOptions.withCustomer('$%s' % variable.customer.name)
  + graph.sloOptions.withAvailability(99)
  + graph.sloOptions.withLatencyMs('avg', 100)
  + graph.sloOptions.withLatencyMs('p99', 500);

local getApiGraph = graph.new('Get API')
  + graph.textOptions.withDescription(
  |||
    The Get operation is used by our customers to retrieve Something they previously stored.
    It is typically a very fast operation, and we can expect a high volume of these operations during peak hours.
  |||)
  + graph.filterOptions.withCustomer('$%s' % variable.customer.name)
  + graph.filterOptions.withService('some-service')
  + graph.filterOptions.withMethod('GET')
  + graph.sloOptions.withAvailability(99.9)
  + graph.sloOptions.withLatencyMs('avg', 100);

local putApiGraph = graph.new('Put API')
  + graph.textOptions.withDescription(
  |||
    The Put operation is used by our customers to store or update something in our system,
    primarily at the end of the workday.
    Since it is a write-heavy operation, it may have higher latency compared to Get.
    We typically observe a spike in Put operations during this period as customers finalize and save their updates.
  |||)
  + graph.filterOptions.withCustomer('$%s' % variable.customer.name)
  + graph.filterOptions.withService('some-service')
  + graph.filterOptions.withMethod('PUT')
  + graph.sloOptions.withAvailability(99.5)
  + graph.sloOptions.withLatencyMs('avg', 200)
  + graph.sloOptions.withLatencyMs('p99', 500);

dashboard.new('CX Customer Level Dashboard')
+ dashboard.withUid('cx-tenant-dashboard')
+ dashboard.withDescription('This is a sample customer experience dashboard')
+ dashboard.withVariables([
  variable.datasource,
  variable.customer,
])
+ dashboard.withPanels([
  row.new('At A Glance')
  + row.withCollapsed(false)
  + row.withGridPos(0),
  someServiceAPIsAtGlance.apiNotes
  + panelOptions.withGridPos(h = 5, w = 6, x = 0, y = 1),
  someServiceAPIsAtGlance.numbers.availability
  + panelOptions.withGridPos(h = 5, w = 6, x = 6, y = 1),
  someServiceAPIsAtGlance.numbers.latency
  + panelOptions.withGridPos(h = 5, w = 6, x = 12, y = 1),
  someServiceAPIsAtGlance.numbers.requests
  + panelOptions.withGridPos(h = 5, w = 6, x = 18, y = 1),

  row.new('HTTP APIs')
  + row.withCollapsed(false)
  + row.withGridPos(5),
  allAPIs.apiNotes
  + panelOptions.withGridPos(h = 10, w = 6, x = 0, y = 6),
  allAPIs.timeSeries.availability
  + panelOptions.withGridPos(h = 10, w = 6, x = 6, y = 6),
  allAPIs.timeSeries.latency
  + panelOptions.withGridPos(h = 10, w = 6, x = 12, y = 6),
  allAPIs.timeSeries.requests
  + panelOptions.withGridPos(h = 10, w = 6, x = 18, y = 6),
  getApiGraph.apiNotes
  + panelOptions.withGridPos(h = 6, w = 6, x = 0, y = 16),
  getApiGraph.timeSeries.availability
  + panelOptions.withGridPos(h = 6, w = 6, x = 6, y = 16),
  getApiGraph.timeSeries.latency
  + panelOptions.withGridPos(h = 6, w = 6, x = 12, y = 16),
  getApiGraph.timeSeries.requests
  + panelOptions.withGridPos(h = 6, w = 6, x = 18, y = 16),
  putApiGraph.apiNotes
  + panelOptions.withGridPos(h = 6, w = 6, x = 0, y = 22),
  putApiGraph.timeSeries.availability
  + panelOptions.withGridPos(h = 6, w = 6, x = 6, y = 22),
  putApiGraph.timeSeries.latency
  + panelOptions.withGridPos(h = 6, w = 6, x = 12, y = 22),
  putApiGraph.timeSeries.requests
  + panelOptions.withGridPos(h = 6, w = 6, x = 18, y = 22),

  row.new('Top Operations by Error rate')
  + row.withCollapsed(false)
  + row.withGridPos(28),
  allAPIs.tables.apiEndpoints
  + panelOptions.withGridPos(h=15, w=24, x=0, y=29),
])
+ dashboard.withLinks([
  link.cxDashboard,
])