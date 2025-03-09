local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local colors = import 'colors.libsonnet';

// TODO: std.minArray() and std.maxArray() will be available in jsonnet 0.21.0
local minArray(arr) = std.sort(std.prune(arr))[0];
local maxArray(arr) = std.sort(std.prune(arr))[std.length(std.prune(arr)) - 1];

{
  text: {
    local text = g.panel.text,

    apiNotes(title, content, links = []):
      text.new(title)
      + text.panelOptions.withTransparent(true)
      + text.panelOptions.withLinks(links)
      + text.options.withMode('markdown')
      + text.options.withContent(content)
  },

  stat: {
    local stat = g.panel.stat,
    local options = stat.options,
    local reduceOptions = options.reduceOptions,
    local panelOptions = stat.panelOptions,
    local standardOptions = stat.standardOptions,
    local thresholds = standardOptions.thresholds,
    local threshold = standardOptions.threshold,
    local override = standardOptions.override,
    local queryOptions = stat.queryOptions,

    base(title, targets, links = []):
      stat.new(title)
      + queryOptions.withTargets(targets)
      + options.withTextMode('value')
      + options.withColorMode('none')
      + options.withGraphMode('none')
      + options.withJustifyMode('center')
      + reduceOptions.withValues(false)
      + reduceOptions.withCalcs(['lastNotNull'])
      + panelOptions.withLinks(links)
      + thresholds.withSteps([
        threshold.step.withValue(null)
        + threshold.step.withColor(colors.blue)
      ]),

    availability(targets, links = [], sloOptions = { availability: null }):
      self.base('Availability (no errors)', targets, links)
      + standardOptions.withUnit('percentunit')
      + if sloOptions != null && sloOptions.availability != null && std.isNumber(sloOptions.availability)
        then
          options.withColorMode('value')
          + thresholds.withSteps([
            threshold.step.withValue(null)
            + threshold.step.withColor(colors.red),
            threshold.step.withValue(sloOptions.availability / 100)
            + threshold.step.withColor(colors.yellow),
            threshold.step.withValue((sloOptions.availability + (100 - sloOptions.availability) * 0.5) / 100)
            + threshold.step.withColor(colors.green),
          ])
        else {},

    latency(targets, links = [], sloOptions = { latency: { avg: null, p95: null, p99: null }}):
      self.base('Latency', targets, links)
      + options.withTextMode('value_and_name')
      + standardOptions.withUnit('s')
      + thresholds.withSteps([
        threshold.step.withValue(null)
        + threshold.step.withColor(colors.text),
      ])
      + if sloOptions != null && sloOptions.latency != null
        then
          options.withColorMode('value')
          + standardOptions.withOverrides(std.filter(
            function(x) x != null,
            [
              if sloOptions.latency.avg != null then
                override.byName.new('avg')
                + override.byName.withProperty('thresholds', {
                  'mode': 'absolute',
                  'steps': [
                    threshold.step.withValue(null)
                    + threshold.step.withColor(colors.green),
                    threshold.step.withValue((sloOptions.latency.avg - sloOptions.latency.avg * 0.2) / 1000)
                    + threshold.step.withColor(colors.yellow),
                    threshold.step.withValue(sloOptions.latency.avg / 1000)
                    + threshold.step.withColor(colors.red),
                  ]
                }),
              if sloOptions.latency.p95!= null then
                override.byName.new('p95')
                + override.byName.withProperty('thresholds', {
                  'mode': 'absolute',
                  'steps': [
                    threshold.step.withValue(null)
                    + threshold.step.withColor(colors.green),
                    threshold.step.withValue((sloOptions.latency.p95 - sloOptions.latency.p95 * 0.2) / 1000)
                    + threshold.step.withColor(colors.yellow),
                    threshold.step.withValue(sloOptions.latency.p95 / 1000)
                    + threshold.step.withColor(colors.red),
                  ]
                }),
              if sloOptions.latency.p99 != null then
                override.byName.new('p99')
                + override.byName.withProperty('thresholds', {
                  'mode': 'absolute',
                  'steps': [
                    threshold.step.withValue(null)
                    + threshold.step.withColor(colors.green),
                    threshold.step.withValue((sloOptions.latency.p99 - sloOptions.latency.p99 * 0.2) / 1000)
                    + threshold.step.withColor(colors.yellow),
                    threshold.step.withValue(sloOptions.latency.p99 / 1000)
                    + threshold.step.withColor(colors.red),
                  ]
                }),
            ])
          )
        else {},

    requests(targets, links = []):
      self.base('Requests', targets, links)
      + standardOptions.withUnit('short')
  },

  timeSeries: {
    local timeSeries = g.panel.timeSeries,
    local fieldOverride = timeSeries.fieldOverride,
    local custom = timeSeries.fieldConfig.defaults.custom,
    local options = timeSeries.options,
    local panelOptions = timeSeries.panelOptions,
    local standardOptions = timeSeries.standardOptions,
    local queryOptions = timeSeries.queryOptions,
    local thresholds = standardOptions.thresholds,
    local threshold = standardOptions.threshold,
    local link = g.dashboard.link,

    base(title, targets, links = []):
      timeSeries.new(title)
      + queryOptions.withTargets(targets)
      + queryOptions.withInterval('1m')
      + options.tooltip.withMode('multi')
      + options.tooltip.withSort('desc')
      + options.legend.withCalcs([])
      + options.legend.withDisplayMode('list')
      + options.legend.withPlacement('bottom')
      + options.legend.withShowLegend(true)
      + panelOptions.withLinks(links)
      + custom.withFillOpacity(10)
      + custom.withAxisPlacement('right')
      + custom.withShowPoints('never'),

    availability(targets, links = [], sloOptions = { availability: null }):
      self.base('Availability', targets, links)
      + standardOptions.withMax(1)
      + standardOptions.withUnit('percentunit')
      + if sloOptions != null && std.objectHas(sloOptions, 'availability') && std.isNumber(sloOptions.availability)
        then
          custom.thresholdsStyle.withMode('dashed')
          + standardOptions.color.withMode('thresholds')
          + thresholds.withSteps([
            threshold.step.withValue(null)
            + threshold.step.withColor(colors.red),
            threshold.step.withValue(sloOptions.availability / 100)
            + threshold.step.withColor(colors.green),
          ])
        else {},

    latency(targets, links = [], sloOptions = { latency: null }):
      self.base('Latency', targets, links)
      + standardOptions.withUnit('s')
      + if sloOptions != null && std.objectHas(sloOptions, 'latency') && std.isNumber(sloOptions.latency)
        then 
          custom.thresholdsStyle.withMode('dashed')
          + thresholds.withSteps([
            threshold.step.withValue(null)
            + threshold.step.withColor(colors.green),
            threshold.step.withValue(sloOptions.latency / 1000)
            + threshold.step.withColor(colors.red),
          ])
        else if sloOptions != null && std.objectHas(sloOptions, 'latency') && std.isArray(sloOptions.latency)
          then
            custom.thresholdsStyle.withMode('dashed')
            + thresholds.withSteps([
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.green),
              threshold.step.withValue(minArray(sloOptions.latency) / 1000)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue(maxArray(sloOptions.latency) / 1000)
              + threshold.step.withColor(colors.red),
            ])
        else {},

    requests(targets, links = []):
      self.base('Requests', targets, links)
      + standardOptions.withUnit('short')
      + standardOptions.withDecimals(0),

    requestRate(targets, links = []):
      self.base('Request Rate', targets, links)
      + standardOptions.withUnit('reqps')
      + standardOptions.withDecimals(2)
      + custom.stacking.withMode('normal')
      + custom.stacking.withGroup('A'),
  },

  table: {
    local table = g.panel.table,
    local options = table.options,
    local queryOptions = table.queryOptions,
    local standardOptions = table.standardOptions,
    local transformation = queryOptions.transformation,
    local override = standardOptions.override,
    local mapping = standardOptions.mapping,
    local thresholds = standardOptions.thresholds,
    local threshold = standardOptions.threshold,

    base(title, targets):
      table.new(title)
      + table.queryOptions.withTargets(targets)
      + options.footer.withEnablePagination(true)
      + thresholds.withSteps([
        threshold.step.withValue(null)
        + threshold.step.withColor(colors.text),
      ]),

    customers(targets, dataLinks = [], sloOptions = { availability: null, latency: { avg: null, p95: null, p99: null } }):
      self.base(title = '', targets = targets)
      + queryOptions.withTransformations([
        transformation.withId('merge')
        + transformation.withOptions({
            reducers: []
          }),
        transformation.withId('organize')
        + transformation.withOptions({
            excludeByName: {
              'Time': true,
            },
            indexByName: {
              'Time': 0,
              'customer': 1,
              'Value #A': 2,
              'Value #B': 3,
              'Value #C': 4,
              'Value #D': 5,
              'Value #E': 6,
            },
            renameByName: {
              'Value #A': 'availability (no errors)',
              'Value #B': 'requests',
              'Value #C': 'avg latency',
              'Value #D': 'p95 latency',
              'Value #E': 'p99 latency',
            },
          }),
        transformation.withId('filterByValue')
        + transformation.withOptions({
            match: 'any',
            type: 'exclude',
            filters: [
              {
                fieldName: 'customer',
                config: {
                  id: 'equal',
                  options: { value: "" },
                },
              },
              {
                fieldName: 'availability (no errors)',
                config: {
                  id: 'isNull',
                  options: {},
                },
              },
              {
                fieldName: 'requests',
                config: {
                  id: 'lowerOrEqual',
                  options: { value: 0 },
                },
              },
            ],
        }),
      ])
      + standardOptions.withOverrides([
        override.byName.new('customer')
        + override.byName.withProperty('custom.width', 300)
        + override.byName.withProperty('links', dataLinks),
        override.byName.new('availability (no errors)')
        + override.byName.withProperty('unit', 'percentunit')
        + override.byName.withProperty('decimals', 2)
        + override.byName.withProperty('max', 0.5)
        + (if sloOptions != null && sloOptions.availability != null then
          override.byName.withProperty('custom.cellOptions', { type: 'color-background' })
          + override.byName.withProperty('max', sloOptions.availability/100)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.red),
              threshold.step.withValue(sloOptions.availability/100)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue((sloOptions.availability + (100 - sloOptions.availability) * 0.5)/100)
              + threshold.step.withColor(colors.transparent),
            ]
          }) else {}),
        override.byName.new('requests')
        + override.byName.withProperty('unit', 'short'),
        override.byName.new('avg latency')
        + override.byName.withProperty('unit', 's')
        + override.byName.withProperty('decimals', 1)
        + override.byName.withProperty('custom.cellOptions', { type: 'gauge', mode: 'basic' })
        + override.byName.withProperty('min', 0)
        + (if sloOptions != null && sloOptions.latency != null && sloOptions.latency.avg != null then
          override.byName.withProperty('max', sloOptions.latency.avg / 1000)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.green),
              threshold.step.withValue((sloOptions.latency.avg - sloOptions.latency.avg*0.2) / 1000)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue(sloOptions.latency.avg / 1000)
              + threshold.step.withColor(colors.red),
            ]
          }) else {}),
        override.byName.new('p95 latency')
        + override.byName.withProperty('unit', 's')
        + override.byName.withProperty('decimals', 1)
        + override.byName.withProperty('custom.cellOptions', { type: 'gauge', mode: 'basic' })
        + override.byName.withProperty('min', 0)
        + (if sloOptions != null && sloOptions.latency != null && sloOptions.latency.p95 != null then
          override.byName.withProperty('max', sloOptions.latency.p95 / 1000)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.green),
              threshold.step.withValue((sloOptions.latency.p95 - sloOptions.latency.p95*0.2) / 1000)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue(sloOptions.latency.p95 / 1000)
              + threshold.step.withColor(colors.red),
            ]
          }) else {}),
        override.byName.new('p99 latency')
        + override.byName.withProperty('unit', 's')
        + override.byName.withProperty('decimals', 2)
        + override.byName.withProperty('custom.cellOptions', { type: 'gauge', mode: 'basic' })
        + override.byName.withProperty('min', 0)
        + (if sloOptions != null && sloOptions.latency != null && sloOptions.latency.p99 != null then
          override.byName.withProperty('max', sloOptions.latency.p99 / 1000)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.green),
              threshold.step.withValue((sloOptions.latency.p99 - sloOptions.latency.p99*0.2) / 1000)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue(sloOptions.latency.p99 / 1000)
              + threshold.step.withColor(colors.red),
            ]
          }) else {}),
      ])
      + options.withSortBy({ displayName: 'availability (no errors)', desc: false }),

    apiEndpoints(targets, sloOptions = { availability: null, latency: { avg: null, p95: null, p99: null } }):
      self.base(title = '', targets = targets)
      + queryOptions.withTransformations([
        transformation.withId('merge')
        + transformation.withOptions({ 
            reducers: []
          }),
        transformation.withId('organize')
        + transformation.withOptions({
            excludeByName: {
              'Time': true,
            },
            indexByName: {
              'Time': 0,
              'http_route': 1,
              'http_request_method': 2,
              'Value #A': 3,
              'Value #B': 4,
              'Value #C': 5,
              'Value #D': 6,
              'Value #E': 6,
            },
            renameByName: {
              'http_route': 'route',
              'http_request_method': 'method',
              'Value #A': 'availability (no errors)',
              'Value #B': 'requests',
              'Value #C': 'avg latency',
              'Value #D': 'p95 latency',
              'Value #E': 'p99 latency',
            },
          }),
        transformation.withId('filterByValue')
        + transformation.withOptions({
            match: 'any',
            type: 'exclude',
            filters: [
              {
                fieldName: 'availability (no errors)',
                config: {
                  id: 'isNull',
                  options: {},
                },
              },
              {
                fieldName: 'requests',
                config: {
                  id: 'lowerOrEqual',
                  options: { value: 0 },
                },
              },
            ],
        }),
      ])
      + standardOptions.withOverrides([
        override.byName.new('route')
        + override.byName.withProperty('custom.width', 600),
        override.byName.new('availability (no errors)')
        + override.byName.withProperty('custom.width', 200)
        + override.byName.withProperty('unit', 'percentunit')
        + override.byName.withProperty('decimals', 2)
        + override.byName.withProperty('max', 0.5)
        + (if sloOptions != null && sloOptions.availability != null then
          override.byName.withProperty('custom.cellOptions', { type: 'color-background' })
          + override.byName.withProperty('max', sloOptions.availability/100)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.red),
              threshold.step.withValue(sloOptions.availability/100)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue((sloOptions.availability + (100 - sloOptions.availability) * 0.5)/100)
              + threshold.step.withColor(colors.transparent),
            ]
          }) else {}),
        override.byName.new('requests')
        + override.byName.withProperty('custom.width', 100)
        + override.byName.withProperty('unit', 'short'),
        override.byName.new('avg latency')
        + override.byName.withProperty('unit', 's')
        + override.byName.withProperty('decimals', 1)
        + override.byName.withProperty('max', 0.2)
        + override.byName.withProperty('custom.cellOptions', { type: 'gauge', mode: 'basic' })
        + (if sloOptions != null && sloOptions.latency != null && sloOptions.latency.avg != null then
          override.byName.withProperty('max', sloOptions.latency.avg / 1000)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.green),
              threshold.step.withValue((sloOptions.latency.avg - sloOptions.latency.avg*0.2) / 1000)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue(sloOptions.latency.avg / 1000)
              + threshold.step.withColor(colors.red),
            ]
          }) else {}),
        override.byName.new('p95 latency')
        + override.byName.withProperty('unit', 's')
        + override.byName.withProperty('decimals', 1)
        + override.byName.withProperty('max', 1)
        + override.byName.withProperty('custom.cellOptions', { type: 'gauge', mode: 'basic' })
        + (if sloOptions != null && sloOptions.latency != null && sloOptions.latency.p95 != null then
          override.byName.withProperty('max', sloOptions.latency.p95 / 1000)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.green),
              threshold.step.withValue((sloOptions.latency.p95 - sloOptions.latency.p95*0.2) / 1000)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue(sloOptions.latency.p95 / 1000)
              + threshold.step.withColor(colors.red),
            ]
          }) else {}),
        override.byName.new('p99 latency')
        + override.byName.withProperty('unit', 's')
        + override.byName.withProperty('decimals', 2)
        + override.byName.withProperty('custom.cellOptions', { type: 'gauge', mode: 'basic' })
        + (if sloOptions != null && sloOptions.latency != null && sloOptions.latency.p99 != null then
          override.byName.withProperty('max', sloOptions.latency.p99 / 1000)
          + override.byName.withProperty('thresholds', {
            'mode': 'absolute',
            'steps': [
              threshold.step.withValue(null)
              + threshold.step.withColor(colors.green),
              threshold.step.withValue((sloOptions.latency.p99 - sloOptions.latency.p99*0.2) / 1000)
              + threshold.step.withColor(colors.yellow),
              threshold.step.withValue(sloOptions.latency.p99 / 1000)
              + threshold.step.withColor(colors.red),
            ]
          }) else {}),
      ])
      + options.withSortBy({ displayName: 'availability (no errors)', desc: false }),
    },
}