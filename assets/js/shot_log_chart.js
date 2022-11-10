import { Chart, Title, Tooltip, Legend, LineController, LineElement, PointElement, TimeScale, LinearScale } from 'chart.js'
import 'chartjs-adapter-date-fns'
Chart.register(Title, Tooltip, Legend, LineController, LineElement, PointElement, TimeScale, LinearScale)

export default {
  initalizeChart (el) {
    const data = JSON.parse(el.dataset.chartData)

    this.el.chart = new Chart(el, {
      type: 'line',
      data: {
        datasets: [{
          label: el.dataset.label,
          data: data.map(({ date, count, labels }) => ({
            labels,
            x: date,
            y: count
          })),
          backgroundColor: el.dataset.color,
          borderColor: el.dataset.color,
          fill: true,
          borderWidth: 4
        }]
      },
      options: {
        elements: {
          point: {
            radius: 7,
            hoverRadius: 10
          }
        },
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 20
            }
          },
          tooltip: {
            displayColors: false,
            callbacks: {
              label: ({ raw: { labels } }) => labels
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            stacked: true,
            grace: '15%',
            ticks: {
              padding: 15
            }
          },
          x: {
            type: 'time',
            time: {
              unit: 'day'
            }
          }
        },
        transitions: {
          show: {
            animations: {
              x: {
                from: 0
              }
            }
          },
          hide: {
            animations: {
              x: {
                to: 0
              }
            }
          }
        }
      }
    })
  },
  mounted () { this.initalizeChart(this.el) },
  updated () { this.initalizeChart(this.el) }
}
