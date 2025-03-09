local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local prometheusQuery = g.query.prometheus;
local variable = import 'variables.libsonnet';

{
  httpServer: {
    new():
      self + {
        options+: {
          format: 'time_series',
          timeWindow: '5m',
          instant: false,
        },
        selector+: {
          customer: null,
          service: null,
          route: null,
          method: null,
        },
        sumBy+: {
          customer: false,
          service: false,
          route: false,
          method: false,
        },
      },

    options+: {
      withFormat(value): {
        options+: {
          format: value,
          instant: value == 'table',
        }
      },
      withTimeWindow(value): {
        options+: {
          timeWindow: value,
        }
      },
    },

    selector+: {
      withCustomer(value):: {
        selector+: {
          customer: value,
        },
      },
      withService(value):: {
        selector+: {
          service: value,
        },
      },
      withRoute(value):: {
        selector+: {
          route: value,
        },
      },
      withMethod(value):: {
        selector+: {
          method: value,
        },
      },
    },

    sumBy+: {
      withCustomer(value=true):: {
        sumBy+: {
          customer: value,
        },
      },
      withService(value=true):: {
        sumBy+: {
          service: value,
        },
      },
      withRoute(value=true):: {
        sumBy+: {
          route: value,
        },
      },
      withMethod(value=true):: {
        sumBy+: {
          method: value,
        },
      },
    },

    local getSumByClause(additionalLabels=[]) = std.join(',', [
        if self.sumBy.customer then 'customer',
        if self.sumBy.service then 'service',
        if self.sumBy.route then 'http_route',
        if self.sumBy.method then 'http_request_method',
      ] + if std.isArray(additionalLabels) then additionalLabels else [ additionalLabels ],
    ),

    local getRequestFilter() = std.join(',', [
      customerSelector,
      serviceSelector,
      routeSelector,
      methodSelector,
    ]),

    local requestSuccessFilter = std.join(',', [
      customerSelector,
      serviceSelector,
      routeSelector,
      methodSelector,
      successCodeSelector,
    ]),

    local customerSelector =
      if self.selector.customer != null then 'customer="%s"' % self.selector.customer,
    local serviceSelector =
      if self.selector.service != null then 'service="%s"' % self.selector.service,
    local routeSelector =
      if self.selector.route != null then 'http_route="%s"' % self.selector.route,
    local methodSelector =
      if self.selector.method != null then 'http_request_method="%s"' % self.selector.method,
    local successCodeSelector = 'http_response_status_code!~"(4|5).."',

    requests:
      prometheusQuery.new(
        '$%s' % variable.datasource.name,
        |||
          sum by (%s) (increase (http_server_request_duration_seconds_count{%s}[%s]))
        ||| % [
          getSumByClause(), getRequestFilter(), self.options.timeWindow,
        ]
      )
      + prometheusQuery.withInterval('30s')
      + prometheusQuery.withFormat(self.options.format)
      + prometheusQuery.withInstant(self.options.instant)
      + prometheusQuery.withLegendFormat('requests'),

    requestRate:
      prometheusQuery.new(
        '$%s' % variable.datasource.name,
        |||
          sum by (%s) (rate (http_server_request_duration_seconds_count{%s}[%s]))
        ||| % [
          getSumByClause(), getRequestFilter(), self.options.timeWindow,
        ]
      )
      + prometheusQuery.withInterval('30s')
      + prometheusQuery.withFormat(self.options.format)
      + prometheusQuery.withInstant(self.options.instant)
      + prometheusQuery.withLegendFormat('rps'),

    requestSuccessRate:
      prometheusQuery.new(
        '$%s' % variable.datasource.name,
        |||
          sum by (%s) (rate (http_server_request_duration_seconds_count{%s}[%s]))
          /
          sum by (%s) (rate (http_server_request_duration_seconds_count{%s}[%s]))
        ||| % [
          getSumByClause(), requestSuccessFilter, self.options.timeWindow,
          getSumByClause(), getRequestFilter(), self.options.timeWindow,
        ]
      )
      + prometheusQuery.withInterval('30s')
      + prometheusQuery.withFormat(self.options.format)
      + prometheusQuery.withInstant(self.options.instant)
      + prometheusQuery.withLegendFormat('availability'),

    local this = self,
    latency: {
      avg:
        prometheusQuery.new(
          '$%s' % variable.datasource.name,
          |||
            sum by (%s) (rate (http_server_request_duration_seconds_sum{%s}[%s]))
            /
            sum by (%s) (rate (http_server_request_duration_seconds_count{%s}[%s]))
          ||| % [
            getSumByClause(), getRequestFilter(), this.options.timeWindow,
            getSumByClause(), getRequestFilter(), this.options.timeWindow,
          ]
        )
        + prometheusQuery.withInterval('30s')
        + prometheusQuery.withFormat(this.options.format)
        + prometheusQuery.withInstant(this.options.instant)
        + prometheusQuery.withLegendFormat('avg'),

      percentile(percentile):
        prometheusQuery.new(
          '$%s' % variable.datasource.name,
          |||
            histogram_quantile (
              0.%s,
              sum by (%s) (rate (http_server_request_duration_seconds_bucket{%s}[%s]))
            )
          ||| % [
            percentile,
            getSumByClause('le'), getRequestFilter(), this.options.timeWindow,
          ],
        )
        + prometheusQuery.withInterval('30s')
        + prometheusQuery.withFormat(this.options.format)
        + prometheusQuery.withInstant(this.options.instant)
        + prometheusQuery.withLegendFormat('p%s' % percentile),
    },
  }
}