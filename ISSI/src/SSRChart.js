import jsonData from './json/SRR107084_2.json'

var sortable = [];
for (var SSR in jsonData) {
    sortable.push([SSR, jsonData[SSR]]);
}

sortable.sort(function(a, b) {
  return a[1] - b[1];
});

var objSorted = {}
sortable.forEach(function(item){
    objSorted[item[0]]=item[1]
})

export const SSRChart = {
  type: 'bar',
  data: {
    labels: Object.keys(objSorted),
    datasets: [
      { // one line graph
        label: 'Number of repeats',
        data: Object.values(objSorted),
        backgroundColor: 'rgba(54,73,93,.5)',
        borderColor: [
          '#36495d',
        ],
        borderWidth: 3,
        barThickness: 2,
      },
    ]
  },
  options: {
    legend: {
      display: false
    },

    tooltips: {
      callbacks: {
        label: function(tooltipItem) {
          return tooltipItem.yLabel;
        }
      }
    },

    scales: {
        xAxes: [{
          display: false //this will remove only the label
        }],

        yAxes: [{
          ticks: {
              beginAtZero:true
          }
        }]
    },
    // Container for pan options
    pan: {
      // Boolean to enable panning
      enabled: true,

      // Panning directions. Remove the appropriate direction to disable 
      // Eg. 'y' would only allow panning in the y direction
      mode: 'xy'
    },

    // Container for zoom options
    zoom: {
      // Boolean to enable zooming
      enabled: true,

      // Zooming directions. Remove the appropriate direction to disable 
      // Eg. 'y' would only allow zooming in the y direction
      mode: 'xy',
    }
  }
}

export default SSRChart;