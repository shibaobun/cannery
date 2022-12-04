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
          data: data.map(({ date, count, label }) => ({
            label,
            x: date,
            y: count
          })),
          backgroundColor: `${el.dataset.color}77`,
          borderColor: el.dataset.color,
          fill: true,
          borderWidth: 3,
          pointBorderWidth: 1
        }]
      },
      options: {
        elements: {
          point: {
            radius: 9,
            hoverRadius: 12
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
              title: (contexts) => contexts.map(({ raw: { x } }) => Intl.DateTimeFormat([], { timeZone: 'Etc/UTC', dateStyle: 'short' }).format(new Date(x))),
              label: ({ raw: { label } }) => label
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
  updateChart (el) {
    const data = JSON.parse(el.dataset.chartData)

    this.el.chart.data = {
      datasets: [{
        label: el.dataset.label,
        data: data.map(({ date, count, label }) => ({
          label,
          x: date,
          y: count
        })),
        backgroundColor: `${el.dataset.color}77`,
        borderColor: el.dataset.color,
        fill: true,
        borderWidth: 3,
        pointBorderWidth: 1
      }]
    }

    this.el.chart.update()
  },
  mounted () { this.initalizeChart(this.el) },
  updated () { this.updateChart(this.el) }
}
