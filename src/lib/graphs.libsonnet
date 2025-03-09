local panel = import 'panels.libsonnet';
local dotnetQuery = import 'dotnet.queries.libsonnet';
local link = import 'links.libsonnet';

{
  new(apiName):
    self + {
      options:: {
        atAGlanceTimeWindow: '$__range',
      },
      textOptions:: {
        apiName: apiName,
        description: null,
        footnotes: null,
      },
      filterOptions:: {
        customer: null,
        service: null,
        method: null,
        route: null,
      },
      sloOptions:: {
        availability: null,
        latency: {
          avg: null,
          p95: null,
          p99: null,
        },
      },
      navigationOptions:: {
        title: null,
        dashboard_url: null,
      },
    },

  local this = self,

  ## Options for configuring a graph
  options+:: {
    ## Sets the time window to be used for At A Glance metrics
    ## @param value (string): The time window
    withAtAGlanceTimeWindow(value): {
      options+:: {
        atAGlanceTimeWindow: value,
      },
    },
  },

  ## Options for configuring text options of the graph controls
  textOptions+:: {
    ## Sets the API description that comes below the title
    ## @param value (string): The description content
    withDescription(value): {
      textOptions+:: {
        description: value,
      },
    },
    ## Sets a footnotes
    ## @param value (string): The footnotes content
    withFootnotes(value): {
      textOptions+:: {
        footnotes: value,
      },
    },
  },

  ## Options for configuring query filters for observability signals: metrics, traces, and logs
  filterOptions+:: {
    ## Sets the customer filter option
    ## @param value (string): The customer identifier
    withCustomer(value): {
      filterOptions+:: {
        customer: value,
      },
    },
    ## Sets the service that exposes the HTTP API endpoint for filtering
    ## @param value (string): The name of the service
    withService(value): {
      filterOptions+:: {
        service: value,
      },
    },
    ## Sets the HTTP API endpoint for filtering
    ## @param route (string): The API endpoint route
    ## @param method (string): The HTTP method used ('GET', 'PUT', 'POST', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')
    withEndpoint(route, method):
      self.withRoute(route)
      + self.withMethod(method),
    ## Sets the HTTP API endpoint route for filtering
    ## @param value (string): The API endpoint route
    withRoute(value): {
      filterOptions+:: {
        route: value,
      },
    },
    ## Sets the HTTP API endpoint method for filtering
    ## @param value (string): The HTTP method used ('GET', 'PUT', 'POST', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')
    withMethod(value):
      assert std.member([ 'GET', 'PUT', 'POST', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS' ], value): '%s is unknown HTTP method!' % value;
      self + {
        filterOptions+:: {
          method: value,
        },
      },
  },

  ## Options for configuring Service Level Objectives (SLOs) for the configured HTTP API
  sloOptions+:: {
    ## Sets the availability SLO
    ## @param value (number): The availability percentage (0.0 - 100.0) to define the SLO (Service Level Objective) for availability
    withAvailability(value): {
      sloOptions+:: {
        availability: value,
      },
    },
    ## Sets the latency SLO
    ## @param latency (string): The latency type to be tracked. Valid values are: 'avg', 'p95', 'p99'
    ## @param value (number): The latency value in milliseconds (ms)
    ## @throws Error if the latency type is unrecognized
    withLatencyMs(latency, value): 
      assert std.member([ 'avg', 'p95', 'p99' ], latency): '%s is unknown latency sloOptions!' % latency;
      self + {
        sloOptions+:: {
          latency+: {
            [ latency ]: value,
          },
        },
      },
  },

  ## Options for configuring navigation to the related dashboards
  navigationOptions+:: {
    ## Sets the option for the zoom-in navigation to the CX of impacted customer
    ## @param title (string): The title to be displayed for the zoom-in dashboard
    ## @param dashboard_url (string): The URL of the dashboard to zoom into
    withZoomIn(title, dashboard_url): {
      navigationOptions+:: {
        title: title,
        dashboard_url: dashboard_url,
      },
    }
  },

  local createQuery(
    filterOptions = { customer: null, service: null, route: null, method: null },
    sumByOptions = { customer: false, route: false, method: false },
  ) = dotnetQuery.httpServer.new()
    + dotnetQuery.httpServer.selector.withCustomer(filterOptions.customer)
    + dotnetQuery.httpServer.selector.withService(filterOptions.service)
    + dotnetQuery.httpServer.selector.withMethod(filterOptions.method)
    + dotnetQuery.httpServer.selector.withRoute(filterOptions.route)
    + dotnetQuery.httpServer.sumBy.withCustomer(std.objectHas(sumByOptions, 'customer') && sumByOptions.customer)
    + dotnetQuery.httpServer.sumBy.withRoute(std.objectHas(sumByOptions, 'route') && sumByOptions.route)
    + dotnetQuery.httpServer.sumBy.withMethod(std.objectHas(sumByOptions, 'method') && sumByOptions.method),

  local query = createQuery(this.filterOptions),
  local latencyQueries = [
    query.latency.avg,
    query.latency.percentile(95),
    query.latency.percentile(99),
  ],

  local atAGlanceQuery = query
    + dotnetQuery.httpServer.options.withTimeWindow(this.options.atAGlanceTimeWindow),
  local atAGlanceLatencyQueries = [
    atAGlanceQuery.latency.avg,
    atAGlanceQuery.latency.percentile(95),
    atAGlanceQuery.latency.percentile(99),
  ],

  local customerImpactQuery = createQuery(this.filterOptions, { customer: true })
    + dotnetQuery.httpServer.options.withFormat('table')
    + dotnetQuery.httpServer.options.withTimeWindow(this.options.atAGlanceTimeWindow),
  local customerImpactQueries = [
    customerImpactQuery.requestSuccessRate,
    customerImpactQuery.requests,
    customerImpactQuery.latency.avg,
    customerImpactQuery.latency.percentile(95),
    customerImpactQuery.latency.percentile(99),
  ],

  local apiEndpointsQuery = createQuery(this.filterOptions, { route: true, method: true })
    + dotnetQuery.httpServer.options.withFormat('table')
    + dotnetQuery.httpServer.options.withTimeWindow(this.options.atAGlanceTimeWindow),
  local apiEndpointsQueries = [
    apiEndpointsQuery.requestSuccessRate,
    apiEndpointsQuery.requests,
    apiEndpointsQuery.latency.avg,
    apiEndpointsQuery.latency.percentile(95),
    apiEndpointsQuery.latency.percentile(99),
  ],

  ## Graph displaying the HTTP API description
  apiNotes: panel.text.apiNotes(
    this.textOptions.apiName,
    if this.textOptions.description != null
      then '%s\n' % this.textOptions.description
      else
        (if this.sloOptions.availability != null then
          '- Availability: should be ' + (if this.sloOptions.availability < 100 then '> ' else '') + std.format('%g%%', this.sloOptions.availability) else '') +
        (if (this.sloOptions.latency.avg != null ||
            this.sloOptions.latency.p95 != null ||
            this.sloOptions.latency.p99 != null)
        then (if this.sloOptions.availability != null then '\n' else '') + '- Latencies:' +
            (if this.sloOptions.latency.avg != null then '\n\t- avg should be < ' + this.sloOptions.latency.avg + 'ms' else '') +
            (if this.sloOptions.latency.p95 != null then '\n\t- p95 should be < ' + this.sloOptions.latency.p95 + 'ms' else '') +
            (if this.sloOptions.latency.p99 != null then '\n\t- p99 should be < ' + this.sloOptions.latency.p99 + 'ms' else '')
        else '') +
    if this.textOptions.footnotes != null then '\n\n%s\n' % this.textOptions.footnotes else '',
    [
    ]),

  numbers: {
    ## Graph displaying availability of the HTTP API as a simple number
    availability: panel.stat.availability(
      atAGlanceQuery.requestSuccessRate,
      links = [
      ],
      sloOptions = this.sloOptions,
    ),
    ## Graph displaying the latencies of the HTTP API as simple number(s)
    latency: panel.stat.latency(
      atAGlanceLatencyQueries,
      links = [
      ],
      sloOptions = this.sloOptions,
    ),
    ## Graph displaying requests to the HTTP API as a simple number
    requests: panel.stat.requests(
      atAGlanceQuery.requests,
    ),
  },

  timeSeries: {
    ## Graph displaying the availability of the HTTP API as a time series
    availability: panel.timeSeries.availability(
      query.requestSuccessRate,
      links = [
      ],
      sloOptions = this.sloOptions,
    ),
    ## Graph displaying the duration of the requests to the HTTP API as a time series
    latency: panel.timeSeries.latency(
      latencyQueries,
      links = [
      ],
      sloOptions = { latency: [ this.sloOptions.latency.avg, this.sloOptions.latency.p95, this.sloOptions.latency.p99 ] },
    ),
    ## Graph displaying the requests to the HTTP API as a time series
    requests: panel.timeSeries.requests(
      query.requests,
    ),
    ## Graph displaying the request rate to the HTTP API as a time series
    requestRate: panel.timeSeries.requestRate(
      query.requestRate,
    ),
  },

  tables: {
    ## Graph displaying a list of impacted customers based on HTTP API metrics
    impactedCustomers: panel.table.customers(
      customerImpactQueries,
      dataLinks = [ link.dataLinks.cxCustomerDashboard ],
      sloOptions = this.sloOptions),
    ## Graph displaying a list of HTTP API endpoints
    apiEndpoints: panel.table.apiEndpoints(
      apiEndpointsQueries,
      this.sloOptions),
  },
}