<template>
    <body>
    <div id="SSRData">
        <div id="SRRTable">
            <vue-table-dynamic 
                :params="params"
                @select="onSelect" 
                @selection-change="onSelectionChange"
                ref="table"></vue-table-dynamic>
        </div>
        <div v-window id="SSRChart">
            <canvas id="TheChart"></canvas>
        </div>
    </div>
    </body>
</template>

<script>
import Chart from 'chart.js';
import VueTableDynamic from 'vue-table-dynamic'
import ChartZoom from 'chartjs-plugin-zoom'

import jsonData from '../assets/SRR107084_2.json'

const random = () => {
    return parseInt(Math.random() * (200 - 1) + 1).toString()
}

var sortable = [];
var objSorted = {};

for (var SSR in jsonData) {
    sortable.push([SSR, jsonData[SSR]]);
}

sortable.sort(function(a, b) {
    return a[1] - b[1];
});

sortable.forEach(function(item){
    objSorted[item[0]]=item[1]
});

const SSRChart = {
    type: 'bar',

    data: {
        labels: Object.keys(objSorted),

        datasets: [{ // one line graph
            label: 'Number of repeats',
            data: Object.values(objSorted),
            backgroundColor: 'rgba(54,73,93,.5)',

            borderColor: [
            '#36495d',
            ],

            borderWidth: 3,
            barThickness: 2,
        },]
    },

    options: {
        reponsive: true,

        legend: {
           display: true
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
            drag: false,
            mode: "xy",

            limits: {
                max: 50,
                min: 0.5
            }
        },
    },
}

export default {
    name: 'SSRData',

    data() {
        return {
            SSRChart,

            params: {
                data: [
                    ['Index', 'SRR', 'Period size', 'Period number', 'Total occurences'],
                ],

                enableSearch: true,
                header: 'row',
                border: true,
                pagination: true,
                pageSize: 20,
                pageSizes: [20, 50, 100, 200],
                showCheck: true,
                sort: [0, 1, 2, 3, 4],
                stripe: true,
            }
        }
    },

    methods: {
        onSelect (isChecked, index, data) {
            console.log('onSelect: ', isChecked, index, data)
            console.log('Checked Data:', this.$refs.table.getCheckedRowDatas(true))
        },

        onSelectionChange (checkedDatas, checkedIndexs, checkedNum) {
            console.log('onSelectionChange: ', checkedDatas, checkedIndexs, checkedNum)
        },

        createChart (chartId, chartData) {
            const ctx = document.getElementById(chartId);
            const myChart = new Chart(ctx, {
                type: chartData.type,
                data: chartData.data,
                options: chartData.options,
            });
        },
    },

    mounted () {
        for (let i = 0; i < 100; i++) {
            this.params.data.push([i+1, `${random()}`, `${random()}`, `${random()}`, `${random()}`])
        }

        this.createChart('TheChart', SSRChart)
    },

    components: { VueTableDynamic, 
                  ChartZoom}
}

// window.resetZoom = function() {
//     window.SSRChart.resetZoom();
// };
// 
// window.toggleDragMode = function() {
//     var chart = window.SSRChart;
//     var zoomOptions = chart.options.plugins.zoom.zoom;
//     zoomOptions.drag = zoomOptions.drag ? false : dragOptions;
//     chart.update();
//     document.getElementById('drag-switch').innerText = zoomOptions.drag ? 'Disable drag mode' : 'Enable drag mode';
// };
</script>

<style>
    #SSRData {
        align-self: center;
        height: 100%;
        overflow: scroll;
    }

    #SRRTable {
        float: left;
        width: 45%;
        margin: 2%;
    }

    #SSRChart {
        float: left;
        width: 45%;
        height: auto;
        margin: 2%;
    }
</style>