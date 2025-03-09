local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local var = g.dashboard.variable;

{
  datasource:
    var.datasource.new('Datasource', 'prometheus')
    + var.constant.generalOptions.showOnDashboard.withNothing(),

  customer:
    var.query.new('Customer')
    + var.query.withDatasourceFromVariable(self.datasource)
    + var.query.queryTypes.withLabelValues('customer', 'http_server_request_duration_seconds_count')
    + var.query.withSort(type='alphabetical', asc=true, caseInsensitive=false)
    + var.query.withRefresh('time'),
}