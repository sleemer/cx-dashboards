local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local variable = import 'variables.libsonnet';
local link = g.panel.text.panelOptions.link;

{
  cxDashboard::
    link.withTitle('Zoom-out to the CX Dashboard')
    + link.withAsDropdown(false)
    + link.withIcon('dashboard')
    + link.withTargetBlank(false)
    + link.withType('link')
    + link.withIncludeVars(true)
    + link.withKeepTime(true)
    + link.withUrl('/d/cx-dashboard/cx-dashboard'),

  dataLinks:: {
    cxCustomerDashboard:
      link.withTitle('Zoom-in to the ${__data.fields.customer} CX Dashboard')
      + link.withAsDropdown(false)
      + link.withIcon('dashboard')
      + link.withTargetBlank(false)
      + link.withType('link')
      + link.withIncludeVars(true)
      + link.withKeepTime(true)
      + link.withUrl('/d/cx-tenant-dashboard/cx-tenant-dashboard?var-Datasource=${Datasource}&var-Customer=${__data.fields.customer}&${__url_time_range}')
  },
}
