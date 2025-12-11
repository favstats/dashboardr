# Create Scatter Plot

Creates interactive scatter plots showing relationships between two
continuous variables. Supports optional color grouping, custom sizing,
and trend lines.

## Usage

``` r
create_scatter(
  data,
  x_var,
  y_var,
  color_var = NULL,
  size_var = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  color_palette = NULL,
  point_size = 4,
  show_trend = FALSE,
  trend_method = "lm",
  alpha = 0.7,
  include_na = FALSE,
  na_label = "Missing",
  tooltip_format = NULL,
  jitter = FALSE,
  jitter_amount = 0.2
)
```

## Arguments

- data:

  A data frame containing the data.

- x_var:

  Character string. Name of the variable for the x-axis (continuous or
  categorical).

- y_var:

  Character string. Name of the variable for the y-axis (continuous).

- color_var:

  Optional character string. Name of grouping variable for coloring
  points.

- size_var:

  Optional character string. Name of variable to control point sizes.

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- x_label:

  Optional label for the x-axis. Defaults to `x_var` name.

- y_label:

  Optional label for the y-axis. Defaults to `y_var` name.

- color_palette:

  Optional character vector of colors for the points.

- point_size:

  Numeric. Default size for points when `size_var` is not specified.
  Defaults to 4.

- show_trend:

  Logical. Whether to add a trend line. Defaults to `FALSE`.

- trend_method:

  Character string. Method for trend line: "lm" (linear) or "loess".
  Defaults to "lm".

- alpha:

  Numeric between 0 and 1. Transparency of points. Defaults to 0.7.

- include_na:

  Logical. Whether to include NA values in color grouping. Defaults to
  `FALSE`.

- na_label:

  Character string. Label for NA category if `include_na = TRUE`.
  Defaults to "Missing".

- tooltip_format:

  Character string. Custom format for tooltips. Can use x, y, color
  placeholders.

- jitter:

  Logical. Whether to add jittering to reduce overplotting. Defaults to
  `FALSE`.

- jitter_amount:

  Numeric. Amount of jittering if `jitter = TRUE`. Defaults to 0.2.

## Value

A highcharter plot object.

## Examples

``` r
# Simple scatter plot
plot1 <- create_scatter(
  data = mtcars,
  x_var = "wt",
  y_var = "mpg",
  title = "Car Weight vs MPG"
)
plot1

{"x":{"hc_opts":{"chart":{"reflow":true,"type":"scatter","zoomType":"xy"},"title":{"text":"Car Weight vs MPG"},"yAxis":{"title":{"text":"mpg"},"gridLineWidth":1},"credits":{"enabled":false},"exporting":{"enabled":false},"boost":{"enabled":false},"plotOptions":{"series":{"label":{"enabled":false},"turboThreshold":0},"treemap":{"layoutAlgorithm":"squarified"}},"xAxis":{"title":{"text":"wt"},"gridLineWidth":1},"series":[{"data":[{"x":2.62,"y":21},{"x":2.875,"y":21},{"x":2.32,"y":22.8},{"x":3.215,"y":21.4},{"x":3.44,"y":18.7},{"x":3.46,"y":18.1},{"x":3.57,"y":14.3},{"x":3.19,"y":24.4},{"x":3.15,"y":22.8},{"x":3.44,"y":19.2},{"x":3.44,"y":17.8},{"x":4.07,"y":16.4},{"x":3.73,"y":17.3},{"x":3.78,"y":15.2},{"x":5.25,"y":10.4},{"x":5.424,"y":10.4},{"x":5.345,"y":14.7},{"x":2.2,"y":32.4},{"x":1.615,"y":30.4},{"x":1.835,"y":33.9},{"x":2.465,"y":21.5},{"x":3.52,"y":15.5},{"x":3.435,"y":15.2},{"x":3.84,"y":13.3},{"x":3.845,"y":19.2},{"x":1.935,"y":27.3},{"x":2.14,"y":26},{"x":1.513,"y":30.4},{"x":3.17,"y":15.8},{"x":2.77,"y":19.7},{"x":3.57,"y":15},{"x":2.78,"y":21.4}],"type":null,"name":"mpg","marker":{"radius":4,"fillOpacity":0.7}}],"tooltip":{"useHTML":true,"headerFormat":"","pointFormat":"<b>wt:<\/b> {point.x}<br/><b>mpg:<\/b> {point.y}"},"legend":{"enabled":false}},"theme":{"chart":{"backgroundColor":"transparent"},"colors":["#7cb5ec","#434348","#90ed7d","#f7a35c","#8085e9","#f15c80","#e4d354","#2b908f","#f45b5b","#91e8e1"]},"conf_opts":{"global":{"Date":null,"VMLRadialGradientURL":"http =//code.highcharts.com/list(version)/gfx/vml-radial-gradient.png","canvasToolsURL":"http =//code.highcharts.com/list(version)/modules/canvas-tools.js","getTimezoneOffset":null,"timezoneOffset":0,"useUTC":true},"lang":{"contextButtonTitle":"Chart context menu","decimalPoint":".","downloadCSV":"Download CSV","downloadJPEG":"Download JPEG image","downloadPDF":"Download PDF document","downloadPNG":"Download PNG image","downloadSVG":"Download SVG vector image","downloadXLS":"Download XLS","drillUpText":"◁ Back to {series.name}","exitFullscreen":"Exit from full screen","exportData":{"annotationHeader":"Annotations","categoryDatetimeHeader":"DateTime","categoryHeader":"Category"},"hideData":"Hide data table","invalidDate":null,"loading":"Loading...","months":["January","February","March","April","May","June","July","August","September","October","November","December"],"noData":"No data to display","numericSymbolMagnitude":1000,"numericSymbols":["k","M","G","T","P","E"],"printChart":"Print chart","resetZoom":"Reset zoom","resetZoomTitle":"Reset zoom level 1:1","shortMonths":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"shortWeekdays":["Sat","Sun","Mon","Tue","Wed","Thu","Fri"],"thousandsSep":" ","viewData":"View data table","viewFullscreen":"View in full screen","weekdays":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]}},"type":"chart","fonts":[],"debug":false},"evals":[],"jsHooks":[]}
# Scatter plot with color grouping
plot2 <- create_scatter(
  data = iris,
  x_var = "Sepal.Length",
  y_var = "Sepal.Width",
  color_var = "Species",
  title = "Iris Sepal Measurements"
)
plot2

{"x":{"hc_opts":{"chart":{"reflow":true,"type":"scatter","zoomType":"xy"},"title":{"text":"Iris Sepal Measurements"},"yAxis":{"title":{"text":"Sepal.Width"},"gridLineWidth":1},"credits":{"enabled":false},"exporting":{"enabled":false},"boost":{"enabled":false},"plotOptions":{"series":{"label":{"enabled":false},"turboThreshold":0},"treemap":{"layoutAlgorithm":"squarified"}},"xAxis":{"title":{"text":"Sepal.Length"},"gridLineWidth":1},"series":[{"data":[{"x":5.1,"y":3.5},{"x":4.9,"y":3},{"x":4.7,"y":3.2},{"x":4.6,"y":3.1},{"x":5,"y":3.6},{"x":5.4,"y":3.9},{"x":4.6,"y":3.4},{"x":5,"y":3.4},{"x":4.4,"y":2.9},{"x":4.9,"y":3.1},{"x":5.4,"y":3.7},{"x":4.8,"y":3.4},{"x":4.8,"y":3},{"x":4.3,"y":3},{"x":5.8,"y":4},{"x":5.7,"y":4.4},{"x":5.4,"y":3.9},{"x":5.1,"y":3.5},{"x":5.7,"y":3.8},{"x":5.1,"y":3.8},{"x":5.4,"y":3.4},{"x":5.1,"y":3.7},{"x":4.6,"y":3.6},{"x":5.1,"y":3.3},{"x":4.8,"y":3.4},{"x":5,"y":3},{"x":5,"y":3.4},{"x":5.2,"y":3.5},{"x":5.2,"y":3.4},{"x":4.7,"y":3.2},{"x":4.8,"y":3.1},{"x":5.4,"y":3.4},{"x":5.2,"y":4.1},{"x":5.5,"y":4.2},{"x":4.9,"y":3.1},{"x":5,"y":3.2},{"x":5.5,"y":3.5},{"x":4.9,"y":3.6},{"x":4.4,"y":3},{"x":5.1,"y":3.4},{"x":5,"y":3.5},{"x":4.5,"y":2.3},{"x":4.4,"y":3.2},{"x":5,"y":3.5},{"x":5.1,"y":3.8},{"x":4.8,"y":3},{"x":5.1,"y":3.8},{"x":4.6,"y":3.2},{"x":5.3,"y":3.7},{"x":5,"y":3.3}],"type":null,"name":"setosa","marker":{"radius":4,"fillOpacity":0.7}},{"data":[{"x":7,"y":3.2},{"x":6.4,"y":3.2},{"x":6.9,"y":3.1},{"x":5.5,"y":2.3},{"x":6.5,"y":2.8},{"x":5.7,"y":2.8},{"x":6.3,"y":3.3},{"x":4.9,"y":2.4},{"x":6.6,"y":2.9},{"x":5.2,"y":2.7},{"x":5,"y":2},{"x":5.9,"y":3},{"x":6,"y":2.2},{"x":6.1,"y":2.9},{"x":5.6,"y":2.9},{"x":6.7,"y":3.1},{"x":5.6,"y":3},{"x":5.8,"y":2.7},{"x":6.2,"y":2.2},{"x":5.6,"y":2.5},{"x":5.9,"y":3.2},{"x":6.1,"y":2.8},{"x":6.3,"y":2.5},{"x":6.1,"y":2.8},{"x":6.4,"y":2.9},{"x":6.6,"y":3},{"x":6.8,"y":2.8},{"x":6.7,"y":3},{"x":6,"y":2.9},{"x":5.7,"y":2.6},{"x":5.5,"y":2.4},{"x":5.5,"y":2.4},{"x":5.8,"y":2.7},{"x":6,"y":2.7},{"x":5.4,"y":3},{"x":6,"y":3.4},{"x":6.7,"y":3.1},{"x":6.3,"y":2.3},{"x":5.6,"y":3},{"x":5.5,"y":2.5},{"x":5.5,"y":2.6},{"x":6.1,"y":3},{"x":5.8,"y":2.6},{"x":5,"y":2.3},{"x":5.6,"y":2.7},{"x":5.7,"y":3},{"x":5.7,"y":2.9},{"x":6.2,"y":2.9},{"x":5.1,"y":2.5},{"x":5.7,"y":2.8}],"type":null,"name":"versicolor","marker":{"radius":4,"fillOpacity":0.7}},{"data":[{"x":6.3,"y":3.3},{"x":5.8,"y":2.7},{"x":7.1,"y":3},{"x":6.3,"y":2.9},{"x":6.5,"y":3},{"x":7.6,"y":3},{"x":4.9,"y":2.5},{"x":7.3,"y":2.9},{"x":6.7,"y":2.5},{"x":7.2,"y":3.6},{"x":6.5,"y":3.2},{"x":6.4,"y":2.7},{"x":6.8,"y":3},{"x":5.7,"y":2.5},{"x":5.8,"y":2.8},{"x":6.4,"y":3.2},{"x":6.5,"y":3},{"x":7.7,"y":3.8},{"x":7.7,"y":2.6},{"x":6,"y":2.2},{"x":6.9,"y":3.2},{"x":5.6,"y":2.8},{"x":7.7,"y":2.8},{"x":6.3,"y":2.7},{"x":6.7,"y":3.3},{"x":7.2,"y":3.2},{"x":6.2,"y":2.8},{"x":6.1,"y":3},{"x":6.4,"y":2.8},{"x":7.2,"y":3},{"x":7.4,"y":2.8},{"x":7.9,"y":3.8},{"x":6.4,"y":2.8},{"x":6.3,"y":2.8},{"x":6.1,"y":2.6},{"x":7.7,"y":3},{"x":6.3,"y":3.4},{"x":6.4,"y":3.1},{"x":6,"y":3},{"x":6.9,"y":3.1},{"x":6.7,"y":3.1},{"x":6.9,"y":3.1},{"x":5.8,"y":2.7},{"x":6.8,"y":3.2},{"x":6.7,"y":3.3},{"x":6.7,"y":3},{"x":6.3,"y":2.5},{"x":6.5,"y":3},{"x":6.2,"y":3.4},{"x":5.9,"y":3}],"type":null,"name":"virginica","marker":{"radius":4,"fillOpacity":0.7}}],"tooltip":{"useHTML":true,"headerFormat":"","pointFormat":"<b>Sepal.Length:<\/b> {point.x}<br/><b>Sepal.Width:<\/b> {point.y}<br/><b>Species:<\/b> {series.name}"},"legend":{"enabled":true}},"theme":{"chart":{"backgroundColor":"transparent"},"colors":["#7cb5ec","#434348","#90ed7d","#f7a35c","#8085e9","#f15c80","#e4d354","#2b908f","#f45b5b","#91e8e1"]},"conf_opts":{"global":{"Date":null,"VMLRadialGradientURL":"http =//code.highcharts.com/list(version)/gfx/vml-radial-gradient.png","canvasToolsURL":"http =//code.highcharts.com/list(version)/modules/canvas-tools.js","getTimezoneOffset":null,"timezoneOffset":0,"useUTC":true},"lang":{"contextButtonTitle":"Chart context menu","decimalPoint":".","downloadCSV":"Download CSV","downloadJPEG":"Download JPEG image","downloadPDF":"Download PDF document","downloadPNG":"Download PNG image","downloadSVG":"Download SVG vector image","downloadXLS":"Download XLS","drillUpText":"◁ Back to {series.name}","exitFullscreen":"Exit from full screen","exportData":{"annotationHeader":"Annotations","categoryDatetimeHeader":"DateTime","categoryHeader":"Category"},"hideData":"Hide data table","invalidDate":null,"loading":"Loading...","months":["January","February","March","April","May","June","July","August","September","October","November","December"],"noData":"No data to display","numericSymbolMagnitude":1000,"numericSymbols":["k","M","G","T","P","E"],"printChart":"Print chart","resetZoom":"Reset zoom","resetZoomTitle":"Reset zoom level 1:1","shortMonths":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"shortWeekdays":["Sat","Sun","Mon","Tue","Wed","Thu","Fri"],"thousandsSep":" ","viewData":"View data table","viewFullscreen":"View in full screen","weekdays":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]}},"type":"chart","fonts":[],"debug":false},"evals":[],"jsHooks":[]}
# Scatter with trend line and custom colors
plot3 <- create_scatter(
  data = mtcars,
  x_var = "hp",
  y_var = "mpg",
  color_var = "cyl",
  show_trend = TRUE,
  title = "Horsepower vs MPG by Cylinders",
  color_palette = c("#FF6B6B", "#4ECDC4", "#45B7D1")
)
plot3

{"x":{"hc_opts":{"chart":{"reflow":true,"type":"scatter","zoomType":"xy"},"title":{"text":"Horsepower vs MPG by Cylinders"},"yAxis":{"title":{"text":"mpg"},"gridLineWidth":1},"credits":{"enabled":false},"exporting":{"enabled":false},"boost":{"enabled":false},"plotOptions":{"series":{"label":{"enabled":false},"turboThreshold":0},"treemap":{"layoutAlgorithm":"squarified"}},"xAxis":{"title":{"text":"hp"},"gridLineWidth":1},"series":[{"data":[{"x":110,"y":21},{"x":110,"y":21},{"x":110,"y":21.4},{"x":105,"y":18.1},{"x":123,"y":19.2},{"x":123,"y":17.8},{"x":175,"y":19.7}],"type":null,"name":"6","marker":{"radius":4,"fillOpacity":0.7}},{"data":[{"x":93,"y":22.8},{"x":62,"y":24.4},{"x":95,"y":22.8},{"x":66,"y":32.4},{"x":52,"y":30.4},{"x":65,"y":33.9},{"x":97,"y":21.5},{"x":66,"y":27.3},{"x":91,"y":26},{"x":113,"y":30.4},{"x":109,"y":21.4}],"type":null,"name":"4","marker":{"radius":4,"fillOpacity":0.7}},{"data":[{"x":175,"y":18.7},{"x":245,"y":14.3},{"x":180,"y":16.4},{"x":180,"y":17.3},{"x":180,"y":15.2},{"x":205,"y":10.4},{"x":215,"y":10.4},{"x":230,"y":14.7},{"x":150,"y":15.5},{"x":150,"y":15.2},{"x":245,"y":13.3},{"x":175,"y":19.2},{"x":264,"y":15.8},{"x":335,"y":15}],"type":null,"name":"8","marker":{"radius":4,"fillOpacity":0.7}},{"data":[{"x":52,"y":26.55099007990118},{"x":54.85858585858586,"y":26.35595368905014},{"x":57.71717171717172,"y":26.16091729819911},{"x":60.57575757575758,"y":25.96588090734807},{"x":63.43434343434343,"y":25.77084451649704},{"x":66.29292929292929,"y":25.575808125646},{"x":69.15151515151516,"y":25.38077173479496},{"x":72.01010101010101,"y":25.18573534394393},{"x":74.86868686868686,"y":24.99069895309289},{"x":77.72727272727272,"y":24.79566256224186},{"x":80.58585858585859,"y":24.60062617139082},{"x":83.44444444444444,"y":24.40558978053978},{"x":86.30303030303031,"y":24.21055338968875},{"x":89.16161616161617,"y":24.01551699883771},{"x":92.02020202020202,"y":23.82048060798668},{"x":94.87878787878788,"y":23.62544421713564},{"x":97.73737373737373,"y":23.43040782628461},{"x":100.5959595959596,"y":23.23537143543357},{"x":103.4545454545455,"y":23.04033504458254},{"x":106.3131313131313,"y":22.8452986537315},{"x":109.1717171717172,"y":22.65026226288047},{"x":112.030303030303,"y":22.45522587202943},{"x":114.8888888888889,"y":22.2601894811784},{"x":117.7474747474747,"y":22.06515309032736},{"x":120.6060606060606,"y":21.87011669947632},{"x":123.4646464646465,"y":21.67508030862529},{"x":126.3232323232323,"y":21.48004391777425},{"x":129.1818181818182,"y":21.28500752692322},{"x":132.040404040404,"y":21.08997113607218},{"x":134.8989898989899,"y":20.89493474522115},{"x":137.7575757575758,"y":20.69989835437011},{"x":140.6161616161616,"y":20.50486196351908},{"x":143.4747474747475,"y":20.30982557266804},{"x":146.3333333333333,"y":20.11478918181701},{"x":149.1919191919192,"y":19.91975279096597},{"x":152.0505050505051,"y":19.72471640011494},{"x":154.9090909090909,"y":19.5296800092639},{"x":157.7676767676768,"y":19.33464361841286},{"x":160.6262626262626,"y":19.13960722756183},{"x":163.4848484848485,"y":18.94457083671079},{"x":166.3434343434344,"y":18.74953444585976},{"x":169.2020202020202,"y":18.55449805500872},{"x":172.0606060606061,"y":18.35946166415768},{"x":174.9191919191919,"y":18.16442527330665},{"x":177.7777777777778,"y":17.96938888245561},{"x":180.6363636363636,"y":17.77435249160458},{"x":183.4949494949495,"y":17.57931610075354},{"x":186.3535353535354,"y":17.38427970990251},{"x":189.2121212121212,"y":17.18924331905147},{"x":192.0707070707071,"y":16.99420692820044},{"x":194.9292929292929,"y":16.7991705373494},{"x":197.7878787878788,"y":16.60413414649837},{"x":200.6464646464646,"y":16.40909775564733},{"x":203.5050505050505,"y":16.2140613647963},{"x":206.3636363636364,"y":16.01902497394526},{"x":209.2222222222222,"y":15.82398858309422},{"x":212.0808080808081,"y":15.62895219224319},{"x":214.9393939393939,"y":15.43391580139215},{"x":217.7979797979798,"y":15.23887941054112},{"x":220.6565656565656,"y":15.04384301969008},{"x":223.5151515151515,"y":14.84880662883905},{"x":226.3737373737374,"y":14.65377023798801},{"x":229.2323232323232,"y":14.45873384713698},{"x":232.0909090909091,"y":14.26369745628594},{"x":234.9494949494949,"y":14.06866106543491},{"x":237.8080808080808,"y":13.87362467458387},{"x":240.6666666666667,"y":13.67858828373284},{"x":243.5252525252525,"y":13.4835518928818},{"x":246.3838383838384,"y":13.28851550203076},{"x":249.2424242424242,"y":13.09347911117973},{"x":252.1010101010101,"y":12.89844272032869},{"x":254.959595959596,"y":12.70340632947766},{"x":257.8181818181818,"y":12.50836993862662},{"x":260.6767676767677,"y":12.31333354777559},{"x":263.5353535353535,"y":12.11829715692455},{"x":266.3939393939394,"y":11.92326076607352},{"x":269.2525252525253,"y":11.72822437522248},{"x":272.1111111111111,"y":11.53318798437145},{"x":274.969696969697,"y":11.33815159352041},{"x":277.8282828282828,"y":11.14311520266938},{"x":280.6868686868687,"y":10.94807881181834},{"x":283.5454545454545,"y":10.7530424209673},{"x":286.4040404040404,"y":10.55800603011627},{"x":289.2626262626263,"y":10.36296963926523},{"x":292.1212121212121,"y":10.1679332484142},{"x":294.979797979798,"y":9.97289685756316},{"x":297.8383838383838,"y":9.777860466712125},{"x":300.6969696969697,"y":9.58282407586109},{"x":303.5555555555555,"y":9.387787685010055},{"x":306.4141414141415,"y":9.192751294159017},{"x":309.2727272727273,"y":8.997714903307985},{"x":312.1313131313131,"y":8.80267851245695},{"x":314.989898989899,"y":8.607642121605913},{"x":317.8484848484849,"y":8.412605730754875},{"x":320.7070707070707,"y":8.217569339903839},{"x":323.5656565656566,"y":8.022532949052804},{"x":326.4242424242424,"y":7.827496558201769},{"x":329.2828282828283,"y":7.632460167350734},{"x":332.1414141414141,"y":7.437423776499699},{"x":335,"y":7.242387385648664}],"type":"line","name":"Trend","marker":{"enabled":false},"color":"#FF4444","dashStyle":"dash","enableMouseTracking":false,"showInLegend":true}],"colors":["#FF6B6B","#4ECDC4","#45B7D1"],"tooltip":{"useHTML":true,"headerFormat":"","pointFormat":"<b>hp:<\/b> {point.x}<br/><b>mpg:<\/b> {point.y}<br/><b>cyl:<\/b> {series.name}"},"legend":{"enabled":true}},"theme":{"chart":{"backgroundColor":"transparent"},"colors":["#7cb5ec","#434348","#90ed7d","#f7a35c","#8085e9","#f15c80","#e4d354","#2b908f","#f45b5b","#91e8e1"]},"conf_opts":{"global":{"Date":null,"VMLRadialGradientURL":"http =//code.highcharts.com/list(version)/gfx/vml-radial-gradient.png","canvasToolsURL":"http =//code.highcharts.com/list(version)/modules/canvas-tools.js","getTimezoneOffset":null,"timezoneOffset":0,"useUTC":true},"lang":{"contextButtonTitle":"Chart context menu","decimalPoint":".","downloadCSV":"Download CSV","downloadJPEG":"Download JPEG image","downloadPDF":"Download PDF document","downloadPNG":"Download PNG image","downloadSVG":"Download SVG vector image","downloadXLS":"Download XLS","drillUpText":"◁ Back to {series.name}","exitFullscreen":"Exit from full screen","exportData":{"annotationHeader":"Annotations","categoryDatetimeHeader":"DateTime","categoryHeader":"Category"},"hideData":"Hide data table","invalidDate":null,"loading":"Loading...","months":["January","February","March","April","May","June","July","August","September","October","November","December"],"noData":"No data to display","numericSymbolMagnitude":1000,"numericSymbols":["k","M","G","T","P","E"],"printChart":"Print chart","resetZoom":"Reset zoom","resetZoomTitle":"Reset zoom level 1:1","shortMonths":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"shortWeekdays":["Sat","Sun","Mon","Tue","Wed","Thu","Fri"],"thousandsSep":" ","viewData":"View data table","viewFullscreen":"View in full screen","weekdays":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]}},"type":"chart","fonts":[],"debug":false},"evals":[],"jsHooks":[]}
```
