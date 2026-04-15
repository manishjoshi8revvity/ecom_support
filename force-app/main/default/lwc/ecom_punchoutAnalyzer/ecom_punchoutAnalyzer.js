import { LightningElement, track } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import LightningAlert from "lightning/alert";
import ECOM_Punchout_Logs from "@salesforce/resourceUrl/ECOM_Punchout_Logs";
import getCustomerNames from "@salesforce/apex/ECOM_ApplicationLogsController.getCustomerNames";
import getCurrencyValues from "@salesforce/apex/ECOM_ApplicationLogsController.getCurrencyValues";
import getPunchoutLogs from "@salesforce/apex/ECOM_ApplicationLogsController.getPunchoutLogs";
import getPunchoutLogsByCustomer from "@salesforce/apex/ECOM_ApplicationLogsController.getPunchoutLogsByCustomer";

export default class Ecom_punchoutAnalyzer extends LightningElement {
  thirdPartyLibLoaded = false;
  thirdPartyLoadCompleted = false;

  formLoading = true;
  chartLoading = false;
  chartInitialized = false;

  maxDayLevelDiff = 31 * 24 * 60 * 60 * 1000;
  maxMonthLevelDiff = 24;
  allCustomersText = "All Customers";
  allCurrenciesText = "All Currencies";
  weekdays = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
  ];
  customerLevelMaxBars = 10;
  blankPlaceholder = "<blank>";
  blankAccessor(value, data, type, params, column) {
    value == this.blankPlaceholder ? "" : value;
  }

  customerList = [];
  currencyList = [];

  get dataLoading() {
    return this.formLoading || this.chartLoading;
  }

  todayObj = new Date();
  today = this.todayObj.toISOString().substring(0, 10);
  endDateMin = this.today;
  endDateMax = this.today;

  @track currentFilters = {
    startDate: this.today,
    endDate: this.today,
    customer: [],
    currency: []
  };

  #resizeCallback;

  getFilterOptions(test) {
    this.formLoading = true;
    test = test ? true : false;

    Promise.all([
      getCustomerNames({ includeTest: test }),
      getCurrencyValues({ includeTest: test })
    ])
      .then((results) => {
        this.customerList = results[0]
          ? results[0].map((ar) => ar.ERP_Account_Name__c)
          : [];

        this.currencyList = results[1]
          ? results[1].map((ar) => ar.CurrencyIsoCode)
          : [];
      })
      .catch((error) => {
        console.log("Error fetching customer names or currency", error);
      })
      .finally(() => {
        this.formLoading = false;
      });
  }

  handleTestToggle() {
    this.getFilterOptions(this.refs.testIndicator?.checked);
  }

  connectedCallback() {
    this.getFilterOptions(false);

    this.#resizeCallback = this.handleResize.bind(this);
    window.addEventListener("resize", this.#resizeCallback);
  }

  disconnectedCallback() {
    window.removeEventListener("resize", this.#resizeCallback);
  }

  renderedCallback() {
    if (!this.thirdPartyLibLoaded) {
      this.thirdPartyLibLoaded = true;
      Promise.all([
        loadScript(this, ECOM_Punchout_Logs + "/chart.min.js"),
        loadScript(this, ECOM_Punchout_Logs + "/bootstrap.min.js"),
        loadStyle(this, ECOM_Punchout_Logs + "/bootstrap.min.css"),
        loadScript(this, ECOM_Punchout_Logs + "/luxon.min.js"),
        loadScript(this, ECOM_Punchout_Logs + "/tabulator.min.js"),
        loadStyle(this, ECOM_Punchout_Logs + "/tabulator_bootstrap5.min.css")
      ])
        .then(async () => {
          await loadScript(
            this,
            ECOM_Punchout_Logs + "/chartjs-adapter-luxon.min.js"
          );
          this.thirdPartyLoadCompleted = true;
        })
        .catch((error) => {
          console.log("Error loading third party library", error);
        });
    }
  }

  resizeTimeOut;
  handleResize() {
    clearTimeout(this.resizeTimeOut);
    this.resizeTimeOut = setTimeout(() => {
      for (let table in this.allTables) {
        this.allTables[table].redraw(true);
      }
      for (let chart in this.allCharts) {
        this.allCharts[chart].resize();
      }
    }, 1000);
  }

  triggerPicker(e) {
    e.target.showPicker();
  }

  startDateHandleChange() {
    if (this.refs.startDateInput && this.refs.endDateInput) {
      let startDate = this.refs.startDateInput.value;
      let endDate = this.refs.endDateInput.value;

      this.updateCurrentFilter({ startDate: startDate });

      if (startDate) {
        let startDateObj = new Date(startDate);
        let endDateObj = new Date(endDate);

        this.endDateMin = startDate;

        let endDateMaxObj = new Date(
          Math.min(
            this.todayObj.getTime(),
            new Date(
              new Date(startDateObj).setMonth(
                startDateObj.getMonth() + this.maxMonthLevelDiff
              )
            ).getTime()
          )
        );
        let endDateMax = endDateMaxObj.toISOString().substring(0, 10);
        this.endDateMax = endDateMax;

        if (!endDate || startDateObj > endDateObj) {
          this.updateCurrentFilter({ endDate: startDate });
        } else if (endDateObj > endDateMaxObj) {
          this.updateCurrentFilter({ endDate: endDateMax });
        }
      }
    }
  }

  endDateHandleChange() {
    this.updateCurrentFilter({ endDate: this.refs.endDateInput.value });
  }

  customerSelectHandleChange(event) {
    this.updateCurrentFilter({ customer: [...event.detail] });
  }

  currencySelectHandleChange(event) {
    this.updateCurrentFilter({ currency: [...event.detail] });
  }

  updateCurrentFilter(newValues) {
    this.currentFilters = {
      ...this.currentFilters,
      ...newValues
    };
  }

  resetForm() {
    if (
      this.refs.startDateInput &&
      this.refs.endDateInput &&
      this.refs.customerInput &&
      this.refs.currencyInput
    ) {
      this.refs.customerInput.resetToDefault();
      this.refs.currencyInput.resetToDefault();

      this.updateCurrentFilter({
        startDate: this.today,
        endDate: this.today,
        customer: [],
        currency: []
      });
    }
  }

  resultCurrencies = [];
  resultOrderDataMap = {};
  resultCartReturnMap = {};
  resultLabels = [];
  currentGrouping = "month";

  resultCustomerList = [];
  resultCustomerCount = 0;
  resultCustomerDataMap = {};
  resultCustomerCurrencies = [];

  async handleSubmit() {
    try {
      let startDate = this.currentFilters.startDate;
      let endDate = this.currentFilters.endDate;
      let customer = this.currentFilters.customer || [];
      let currency = this.currentFilters.currency || [];

      if (!startDate || !endDate || new Date(startDate) > new Date(endDate)) {
        await LightningAlert.open({
          message: "Please fill valid data in all the fields.",
          theme: "error",
          label: "Error"
        });
        return;
      }

      this.chartInitialized = true;

      let grouping = this.refs.groupingInput.value;
      if (grouping === "date") {
        grouping =
          new Date(endDate).getTime() - new Date(startDate).getTime() >
          this.maxDayLevelDiff
            ? "month"
            : "day";
      }

      this.chartLoading = true;
      let test = this.refs.testIndicator?.checked ? true : false;

      let [result1, result2] = await Promise.all([
        getPunchoutLogs({
          config: {
            startDate,
            endDate,
            customer,
            currency,
            grouping,
            test: test
          }
        }),
        getPunchoutLogsByCustomer({
          config: {
            startDate,
            endDate,
            customer,
            currency,
            grouping,
            test: test
          }
        })
      ]);

      let currencies = new Set();
      let orderDataMap = {};
      let cartReturnMap = {};

      result1.forEach((record) => {
        let key = "";
        if (grouping === "day") {
          key = record.posrDate;
        } else if (grouping === "month") {
          key = record.posrYear + "-" + ("0" + record.posrMonth).slice(-2);
        } else {
          key = this.weekdays[record.posrWeekday - 1];
        }

        if (record.poomCount) {
          currencies.add(record.CurrencyIsoCode);

          orderDataMap[key + "-" + record.CurrencyIsoCode] = {
            orderTotal: record.orderTotal,
            avgOrderTotal: record.avgOrderTotal,
            poomCount: record.poomCount
          };
        }

        let posrCount = record.posrCount || 0;
        let poomCount = record.poomCount || 0;
        let lineItemCount = record.lineItemsTotal || 0;
        let quantityCount = record.quantityTotal || 0;

        if (cartReturnMap[key]) {
          cartReturnMap[key].posrCount += posrCount;
          cartReturnMap[key].poomCount += poomCount;
          cartReturnMap[key].lineItemCount += lineItemCount;
          cartReturnMap[key].quantityCount += quantityCount;
        } else {
          cartReturnMap[key] = {
            posrCount: posrCount,
            poomCount: poomCount,
            lineItemCount: lineItemCount,
            quantityCount: quantityCount
          };
        }
      });

      this.resultCurrencies = Array.from(currencies);
      this.resultOrderDataMap = { ...orderDataMap };
      this.resultCartReturnMap = { ...cartReturnMap };
      this.currentGrouping = grouping;

      let labels = [];

      let currentDateObj = new Date(startDate);
      let endDateObj = new Date(endDate);

      if (grouping === "day") {
        while (currentDateObj <= endDateObj) {
          labels.push(currentDateObj.toISOString().substring(0, 10));
          currentDateObj.setDate(currentDateObj.getDate() + 1);
        }
      } else if (grouping === "month") {
        currentDateObj.setDate(1);
        endDateObj.setDate(1);

        while (currentDateObj <= endDateObj) {
          labels.push(currentDateObj.toISOString().substring(0, 7));
          currentDateObj.setMonth(currentDateObj.getMonth() + 1);
        }
      } else {
        labels = [...this.weekdays];
      }

      this.resultLabels = labels;

      let customerCurrencies = new Set();
      let resultCustomers = new Set();
      let customerDataMap = {};

      result2.forEach((record) => {
        let customerName = record.ERP_Account_Name__c;
        if (!customerName) {
          return;
        }

        let poomPresent = record.poomCount && record.poomCount > 0;

        if (!customerDataMap[customerName]) {
          customerDataMap[customerName] = {
            orderTotal: {},
            avgOrderTotal: {},
            posrCount: 0,
            poomCount: 0,
            lineItemsTotal: 0,
            quantityTotal: 0
          };
        }

        if (poomPresent) {
          let currency = record.CurrencyIsoCode;

          customerCurrencies.add(currency);

          customerDataMap[customerName].orderTotal[currency] =
            record.orderTotal;
          customerDataMap[customerName].avgOrderTotal[currency] =
            record.avgOrderTotal;
          customerDataMap[customerName].poomCount += record.poomCount;
          customerDataMap[customerName].lineItemsTotal += record.lineItemsTotal;
          customerDataMap[customerName].quantityTotal += record.quantityTotal;
        }
        customerDataMap[customerName].posrCount += record.posrCount;

        resultCustomers.add(customerName);
      });

      this.resultCustomerList = Array.from(resultCustomers);
      this.resultCustomerCount = this.resultCustomerList.length;

      this.resultCustomerCurrencies = Array.from(customerCurrencies);
      this.resultCustomerDataMap = { ...customerDataMap };

      this.createOrUpdateCharts();
    } catch (error) {
      console.log(
        "Error fetching punchout logs data (handleSubmit):",
        error,
        error.toString()
      );
      await LightningAlert.open({
        message: "Error fetching punchout logs data. Please try again later.",
        theme: "error",
        label: "Error"
      });
    } finally {
      this.chartLoading = false;
    }
  }

  allCharts = {};

  colorMap = {
    blue: "#36A2EB",
    red: "#FF6384",
    teal: "#4BC0C0",
    orange: "#FF9F40",
    purple: "#9966FF",
    yellow: "#FFCE56",
    green: "#8DD17E",
    gray: "#C9CBCF"
  };

  chartUtil = {
    defaultOptions: {
      responsive: true,
      resizeDelay: 500
    },
    colors: [
      this.colorMap.blue,
      this.colorMap.red,
      this.colorMap.teal,
      this.colorMap.orange,
      this.colorMap.purple,
      this.colorMap.yellow,
      this.colorMap.green,
      this.colorMap.gray
    ],
    tooltipPlugin: {
      usePointStyle: true,
      boxPadding: 2
    },
    timeDisplayFormat: {
      day: "MM/dd",
      month: "yyyy/MM"
    },
    pointStyles: ["circle", "rect", "rectRot", "triangle", "star"],
    interactionSettings: {
      mode: "nearest",
      axis: "xy"
    },
    backgroundColorPlugin: {
      id: "customCanvasBackgroundColor",
      beforeDraw: (chart, args, options) => {
        const { ctx } = chart;
        ctx.save();
        ctx.globalCompositeOperation = "destination-over";
        ctx.fillStyle = options.color || "#fff";
        ctx.fillRect(0, 0, chart.width, chart.height);
        ctx.restore();
      }
    },
    formatThousands: (value, index, ticks) => {
      value = parseFloat(value);
      if (ticks[ticks.length - 1] < 5000) {
        return value.toLocaleString("en-US", {
          minimumFractionDigits: 0,
          maximumFractionDigits: 2
        });
      }
      if (value >= 1000000000) {
        return (
          (value / 1000000000).toLocaleString("en-US", {
            minimumFractionDigits: 0,
            maximumFractionDigits: 1
          }) + "B"
        );
      }
      if (value >= 1000000) {
        return (
          (value / 1000000).toLocaleString("en-US", {
            minimumFractionDigits: 0,
            maximumFractionDigits: 1
          }) + "M"
        );
      }
      if (value >= 1000) {
        return (
          (value / 1000).toLocaleString("en-US", {
            minimumFractionDigits: 0,
            maximumFractionDigits: 1
          }) + "K"
        );
      }
      if (value % 1 !== 0) {
        return value.toLocaleString("en-US", {
          minimumFractionDigits: 0,
          maximumFractionDigits: 2
        });
      }
      return value.toString();
    },
    getXTitleByGrouping: (grouping) => {
      return grouping === "day"
        ? "Date"
        : grouping === "month"
          ? "Month"
          : "Weekdays";
    },
    getXTooltipFormatByGrouping: (grouping) => {
      return grouping === "day" ? "cccc, dd MMM yyyy" : "MMM yyyy";
    },
    formatToolTipNumber: new Intl.NumberFormat("en-US", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    }),
    getTimeGroupingXAxisConfig: (grouping, labels, xTitle, xTooltipFormat) => {
      let xAxisAdditionalConfig = {
        clip: false,
        offset: true,
        title: {
          display: true,
          text: xTitle
        }
      };
      if (grouping !== "week") {
        xAxisAdditionalConfig.type = "time";
        xAxisAdditionalConfig.time = {
          tooltipFormat: xTooltipFormat,
          displayFormats: { ...this.chartUtil.timeDisplayFormat },
          unit: grouping
        };
        xAxisAdditionalConfig.min = labels[0];
        xAxisAdditionalConfig.max = labels[labels.length - 1];
      }
      return xAxisAdditionalConfig;
    }
  };

  allTables = {};

  tableUtil = {
    currencyRowHeader: {
      title: "Currency",
      field: "currency",
      frozen: true
    },
    tableNumberFormatter: (cell) => {
      let val = cell.getValue();

      if (val == this.blankPlaceholder) {
        return "";
      }

      return (
        val?.toLocaleString("en-US", {
          minimumFractionDigits: 0,
          maximumFractionDigits: 2
        }) || "0"
      );
    },
    columnLabelGroupingLogic: (labels, grouping) => {
      return labels.map((label) => {
        return {
          title:
            grouping === "week"
              ? label
              : new Date(label)
                  .toISOString()
                  .substring(
                    grouping === "day" ? 5 : 0,
                    grouping === "day" ? 10 : 7
                  )
                  .replace("-", "/"),
          field: label,
          headerSort: false,
          formatter: this.tableUtil.tableNumberFormatter
        };
      });
    },
    defaultTablePaginationConfig: {
      pagination: "local",
      paginationCounter: "rows",
      paginationSize: 5,
      paginationSizeSelector: [5, 10, 25]
    }
  };

  overallDataCSVFormatter = (list, options, setFileContents) => {
    let row = [];
    let overallCols = [];

    list.forEach((tableRow, rowIndex) => {
      if (rowIndex == 0) {
        overallCols = tableRow.columns[0].component._column.table
          .getColumnLayout()
          .map((el) => el.field);

        let col = [];
        tableRow.columns.forEach((column) => {
          if (column?.value) {
            col.push('"' + column.value.toString().replace(/"/g, '""') + '"');
          }
        });
        row.push(col.join(","));

        return;
      }

      if (rowIndex == 1) {
        let internalRow = [];
        tableRow.component._row.data._children.forEach((child1, idx) => {
          if (idx == 0) {
            internalRow.push('"Total value"');
          } else {
            internalRow.push('"Average value"');
          }
          child1._children.forEach((child2) => {
            let internalCol = [];
            overallCols.forEach((oc) => {
              internalCol.push(
                '"' + child2[oc].toString().replace(/"/g, '""') + '"'
              );
            });
            internalRow.push(internalCol.join(","));
          });
        });
        row.push(internalRow.join("\n"));
        return;
      }

      let internalRow = [`"${tableRow.component._row.data.parameter}"`];
      tableRow.component._row.data._children.forEach((child, idx) => {
        let internalCol = [];
        overallCols.forEach((oc) => {
          internalCol.push(
            '"' + child[oc].toString().replace(/"/g, '""') + '"'
          );
        });
        internalRow.push(internalCol.join(","));
      });
      row.push(internalRow.join("\n"));
      return;
    });

    setFileContents(row.join("\n"), "text/plain");
  };

  customerLevelOverviewCSVFormatter = (list, options, setFileContents) => {
    let row = [];

    list.forEach((tableRow, rowIndex) => {
      let col = [];

      if (rowIndex < 1) {
        return;
      } else if (rowIndex == 1) {
        col.push('"Customer"');
        col.push('"Total return cart"');
      }

      tableRow.columns.forEach((column, colIndex) => {
        if (rowIndex == 1) {
          if (colIndex > 1) {
            let currencyCount = (tableRow.columns.length - 2) / 2;

            if (colIndex < 2 + currencyCount) {
              col.push('"Total ' + column.value + '"');
            } else {
              col.push('"Average ' + column.value + '"');
            }
          }
        } else {
          col.push('"' + column.value?.toString().replace(/"/g, '""') + '"');
        }
      });

      row.push(col.join(","));
    });

    setFileContents(row.join("\n"), "text/plain");
  };

  csvFormatter = (list, options, setFileContents) => {
    let row = [];

    list.forEach((tableRow) => {
      let col = [];

      tableRow.columns.forEach((column) => {
        col.push('"' + column.value?.toString().replace(/"/g, '""') + '"');
      });

      row.push(col.join(","));
    });

    setFileContents(row.join("\n"), "text/plain");
  };

  specialFormatter = {
    customerLevelOverviewTable: this.customerLevelOverviewCSVFormatter,
    overallDataTable: this.overallDataCSVFormatter
  };

  downloadTableAsCSV(e) {
    try {
      let tableId = e.target.dataset.tableId;
      let tableFile = e.target.dataset.tableFile;

      let table = this.allTables[tableId];
      if (!table) {
        return;
      }

      let formatter = this.specialFormatter[tableId] || this.csvFormatter;

      table.download(formatter, tableFile);
    } catch (error) {
      console.log("Error downloading table as CSV:", error.toString());
    }
  }

  createOrUpdateCharts() {
    this.graphReturnCartValue();
    this.graphReturnCartValue("average");
    this.graphReturnCartCount();
    this.graphLineitemsQuantityCount();
    this.graphCustomerLevelReturnCartCount();
    this.graphCustomerLevelLineItemCount();

    this.tableCustomerLevelOverview();
    this.tableOverallData();

    Object.keys(this.allCharts).forEach((chartKey) => {
      if (this.allCharts[chartKey]) {
        this.allCharts[chartKey].update();
      }
    });
  }

  graphReturnCartValue(type = "total") {
    if (
      (type == "total" && !this.refs.canvasReturnCartTotal) ||
      (type == "average" && !this.refs.canvasReturnCartAverage)
    ) {
      return;
    }

    let labels = [...this.resultLabels];

    let currencies = [...this.resultCurrencies];
    if (currencies.length === 0) {
      currencies.push("");
    }

    let grouping = this.currentGrouping;
    let xTitle = this.chartUtil.getXTitleByGrouping(grouping);
    let xTooltipFormat = this.chartUtil.getXTooltipFormatByGrouping(grouping);
    let pointStyles = this.chartUtil.pointStyles;

    const borderDefaultOpacity = "CC";
    const backgroundDefaultOpacity = "99";

    let valueKey = type === "total" ? "orderTotal" : "avgOrderTotal";

    let allData = currencies
      .map((currency, index) => {
        return labels.map((label) => {
          let orderData = this.resultOrderDataMap[label + "-" + currency];
          if (orderData && orderData[valueKey]) {
            return orderData[valueKey];
          }
          return 0;
        });
      })
      .map((data, index) => {
        return {
          label: currencies[index],
          data: data,
          tension: 0.2,
          borderWidth: 2,
          pointStyle: pointStyles[index % pointStyles.length],
          pointRadius: 5,
          borderColor:
            this.chartUtil.colors[index % this.chartUtil.colors.length] +
            borderDefaultOpacity,
          backgroundColor:
            this.chartUtil.colors[index % this.chartUtil.colors.length] +
            backgroundDefaultOpacity
        };
      });

    let xAxisConfig = this.chartUtil.getTimeGroupingXAxisConfig(
      grouping,
      labels,
      xTitle,
      xTooltipFormat
    );

    let chartName =
      type === "total" ? "returnCartTotalChart" : "returnCartAverageChart";
    let chart = this.allCharts[chartName];

    if (!chart) {
      chart = new window.Chart(
        this.refs[
          type === "total" ? "canvasReturnCartTotal" : "canvasReturnCartAverage"
        ].getContext("2d"),
        {
          type: "line",
          data: {
            labels,
            datasets: allData
          },
          options: {
            ...this.chartUtil.defaultOptions,
            plugins: {
              tooltip: {
                ...this.chartUtil.tooltipPlugin,
                callbacks: {
                  label: (context) => {
                    return (
                      context.dataset.label +
                      ": " +
                      this.chartUtil.formatToolTipNumber.format(
                        context.parsed.y
                      )
                    );
                  }
                }
              },
              title: {
                display: true,
                text:
                  type === "total" ? "Return Cart Total" : "Return Cart Average"
              },
              legend: {
                position: "bottom",
                align: "end",
                labels: {
                  usePointStyle: true
                },
                title: {
                  display: true,
                  text: "Currencies"
                }
              }
            },
            scales: {
              x: xAxisConfig,
              y: {
                title: {
                  display: true,
                  text: type === "total" ? "Order Total" : "Order Average"
                },
                beginAtZero: true,
                grace: "5%",
                ticks: {
                  callback: this.chartUtil.formatThousands
                }
              }
            },
            interaction: {
              ...this.chartUtil.interactionSettings,
              intersect: false
            }
          },
          plugins: [this.chartUtil.backgroundColorPlugin]
        }
      );
      this.allCharts[chartName] = chart;
    } else {
      chart.data.labels = labels;
      chart.data.datasets = allData;
      chart.options.scales.x = xAxisConfig;
    }

    this.tableReturnCartValue(type);
  }

  returnCartTotalData;
  returnCartAverageData;
  tableReturnCartValue(type = "total") {
    let labels = [...this.resultLabels];
    let currencies = [...this.resultCurrencies];

    let grouping = this.currentGrouping;

    let columns = [
      {
        title: type === "total" ? "Total" : "Average",
        field: "valuePoint",
        formatter: this.tableUtil.tableNumberFormatter
      },
      ...this.tableUtil.columnLabelGroupingLogic(labels, grouping)
    ];

    let rowHeader = { ...this.tableUtil.currencyRowHeader };
    let valueKey = type === "total" ? "orderTotal" : "avgOrderTotal";

    let tData = currencies.map((currency) => {
      let rowData = { currency };
      let total = 0;
      let poomCount = 0;
      labels.forEach((label) => {
        let orderData = this.resultOrderDataMap[label + "-" + currency];
        if (orderData && orderData[valueKey]) {
          rowData[label] = orderData[valueKey];
          total += orderData.orderTotal;
          poomCount += orderData.poomCount;
        } else {
          rowData[label] = 0;
        }
      });
      rowData["valuePoint"] =
        type === "total" ? total : poomCount > 0 ? total / poomCount : 0;
      return rowData;
    });

    if (type === "total") {
      this.returnCartTotalData = [...tData];
    } else {
      this.returnCartAverageData = [...tData];
    }

    let tableName =
      type === "total" ? "returnCartTotalTable" : "returnCartAverageTable";
    let table = this.allTables[tableName];

    if (!table) {
      table = new window.Tabulator(
        type == "total"
          ? this.refs.tableReturnCartTotal
          : this.refs.tableReturnCartAverage,
        {
          columns,
          rowHeader,
          data: tData
        }
      );

      this.allTables[tableName] = table;
    } else {
      table.setColumns(columns);
      table.replaceData(tData);
      table.redraw(true);
    }
  }

  graphReturnCartCount() {
    if (!this.refs.canvasReturnCartCount) {
      return;
    }

    let labels = [...this.resultLabels];
    let grouping = this.currentGrouping;
    let xTitle = this.chartUtil.getXTitleByGrouping(grouping);
    let xTooltipFormat = this.chartUtil.getXTooltipFormatByGrouping(grouping);
    let pointStyles = this.chartUtil.pointStyles;

    const borderDefaultOpacityBar = "CC";
    const backgroundDefaultOpacityBar = "99";
    const borderDefaultOpacityLine = "CC";
    const backgroundDefaultOpacityLine = "99";

    let sortMethod = (a, b) => {
      return b.datasetIndex - a.datasetIndex;
    };

    let allData = [
      {
        type: "bar",
        label: "All",
        data: labels.map((label) => {
          return this.resultCartReturnMap[label]?.posrCount || 0;
        }),
        yAxisID: "y",
        order: 3,
        borderColor: this.colorMap.yellow + borderDefaultOpacityBar,
        backgroundColor: this.colorMap.yellow + backgroundDefaultOpacityBar
      },
      {
        type: "bar",
        label: "Returns",
        data: labels.map((label) => {
          return this.resultCartReturnMap[label]?.poomCount || 0;
        }),
        yAxisID: "y",
        order: 4,
        borderColor: this.colorMap.green + borderDefaultOpacityBar,
        backgroundColor: this.colorMap.green + backgroundDefaultOpacityBar
      },
      {
        type: "line",
        label: "Percent sessions with return cart",
        data: labels.map((label) => {
          let cartReturn = this.resultCartReturnMap[label];
          if (cartReturn && cartReturn.posrCount && cartReturn.poomCount) {
            return parseFloat(
              ((cartReturn.poomCount / cartReturn.posrCount) * 100).toFixed(2)
            );
          }
          return 0;
        }),
        yAxisID: "y1",
        pointStyle: pointStyles[1],
        pointRadius: 5,
        order: 1,
        borderColor: this.colorMap.purple + borderDefaultOpacityLine,
        backgroundColor: this.colorMap.purple + backgroundDefaultOpacityLine
      },
      {
        type: "line",
        label: "Percent abandoned",
        data: labels.map((label) => {
          let cartReturn = this.resultCartReturnMap[label];
          if (cartReturn && cartReturn.posrCount && cartReturn.poomCount) {
            return parseFloat(
              (
                ((cartReturn.posrCount - cartReturn.poomCount) /
                  cartReturn.posrCount) *
                100
              ).toFixed(2)
            );
          }
          return 100;
        }),
        yAxisID: "y1",
        pointStyle: pointStyles[2],
        pointRadius: 5,
        order: 2,
        borderColor: this.colorMap.red + borderDefaultOpacityLine,
        backgroundColor: this.colorMap.red + backgroundDefaultOpacityLine
      }
    ];

    let xAxisConfig = this.chartUtil.getTimeGroupingXAxisConfig(
      grouping,
      labels,
      xTitle,
      xTooltipFormat
    );

    let chart = this.allCharts["returnCartCountChart"];

    if (!chart) {
      chart = new window.Chart(
        this.refs.canvasReturnCartCount.getContext("2d"),
        {
          type: "bar",
          data: {
            labels,
            datasets: allData
          },
          options: {
            ...this.chartUtil.defaultOptions,
            plugins: {
              tooltip: {
                ...this.chartUtil.tooltipPlugin,
                callbacks: {
                  label: (context) => {
                    if (context.dataset.type === "line") {
                      return (
                        context.dataset.label +
                        ": " +
                        this.chartUtil.formatToolTipNumber.format(
                          context.parsed.y
                        ) +
                        "%"
                      );
                    }
                  }
                },
                itemSort: sortMethod
              },
              title: {
                display: true,
                text: "Return Cart Count"
              },
              legend: {
                position: "bottom",
                align: "end",
                labels: {
                  usePointStyle: true,
                  sort: sortMethod
                },
                title: {
                  display: true,
                  text: "Legend"
                },
                reverse: true
              }
            },
            scales: {
              x: xAxisConfig,
              y: {
                title: {
                  display: true,
                  text: "Sessions"
                },
                beginAtZero: true,
                grace: "5%",
                ticks: {
                  callback: this.chartUtil.formatThousands,
                  count: 11
                }
              },
              y1: {
                title: {
                  display: true,
                  text: "Percent"
                },
                beginAtZero: true,
                position: "right",
                afterBuildTicks: (axis) => {
                  let tick = 0;
                  let ticks = [];
                  while (tick <= 100) {
                    ticks.push({
                      value: tick
                    });
                    tick += 10;
                  }
                  axis.ticks = ticks;
                  axis.max = 100;
                },
                ticks: {
                  callback: (value) => (value > 100 ? "" : value + "%")
                }
              }
            },
            interaction: {
              ...this.chartUtil.interactionSettings,
              intersect: true
            }
          },
          plugins: [this.chartUtil.backgroundColorPlugin]
        }
      );
      this.allCharts["returnCartCountChart"] = chart;
    } else {
      chart.data.labels = labels;
      chart.data.datasets = allData;
      chart.options.scales.x = xAxisConfig;
    }

    this.tableReturnCartCount();
  }

  returnCartCountData;
  tableReturnCartCount() {
    let labels = [...this.resultLabels];

    let grouping = this.currentGrouping;

    let columns = [
      {
        title: "Total",
        field: "total",
        headerSort: false,
        formatter: this.tableUtil.tableNumberFormatter
      },
      ...this.tableUtil.columnLabelGroupingLogic(labels, grouping)
    ];

    let rowHeader = {
      title: "Sessions",
      field: "sessions",
      headerSort: false,
      frozen: true
    };

    let allRowData = { sessions: "All" };
    let returnRowData = { sessions: "Returns carts" };
    let percentReturnRowData = {
      sessions: "Percent sessions with return cart"
    };
    let percentAbandonedRowData = { sessions: "Percent abandoned" };

    let totalSessions = 0;
    let totalReturns = 0;

    labels.forEach((label) => {
      let cartReturn = this.resultCartReturnMap[label];
      let posrCount = cartReturn?.posrCount || 0;
      let poomCount = cartReturn?.poomCount || 0;

      allRowData[label] = posrCount;
      returnRowData[label] = poomCount;
      percentReturnRowData[label] =
        (posrCount ? ((poomCount / posrCount) * 100).toFixed(2) : 0) + "%";
      percentAbandonedRowData[label] =
        (posrCount
          ? (((posrCount - poomCount) / posrCount) * 100).toFixed(2)
          : 100) + "%";

      totalSessions += posrCount;
      totalReturns += poomCount;
    });

    allRowData["total"] = totalSessions;
    returnRowData["total"] = totalReturns;
    percentReturnRowData["total"] =
      (totalSessions ? ((totalReturns / totalSessions) * 100).toFixed(2) : 0) +
      "%";
    percentAbandonedRowData["total"] =
      (totalSessions
        ? (((totalSessions - totalReturns) / totalSessions) * 100).toFixed(2)
        : 100) + "%";

    let tData = [
      allRowData,
      returnRowData,
      percentReturnRowData,
      percentAbandonedRowData
    ];

    this.returnCartCountData = [...tData];

    let table = this.allTables["returnCartCountTable"];

    if (!table) {
      table = new window.Tabulator(this.refs.tableReturnCartCount, {
        columns,
        rowHeader,
        data: tData
      });

      this.allTables["returnCartCountTable"] = table;
    } else {
      table.setColumns(columns);
      table.replaceData(tData);
      table.redraw(true);
    }
  }

  graphLineitemsQuantityCount() {
    if (!this.refs.canvasLineitemsQuantityCount) {
      return;
    }

    let labels = [...this.resultLabels];
    let grouping = this.currentGrouping;
    let xTitle = this.chartUtil.getXTitleByGrouping(grouping);
    let xTooltipFormat = this.chartUtil.getXTooltipFormatByGrouping(grouping);

    const borderDefaultOpacityBar = "CC";
    const backgroundDefaultOpacityBar = "99";
    const borderDefaultOpacityLine = "CC";
    const backgroundDefaultOpacityLine = "99";

    let allData = [
      {
        type: "bar",
        label: "Line items",
        data: labels.map((label) => {
          return this.resultCartReturnMap[label]?.lineItemCount || 0;
        }),
        borderColor: this.colorMap.blue + borderDefaultOpacityBar,
        backgroundColor: this.colorMap.blue + backgroundDefaultOpacityBar
      },
      {
        type: "bar",
        label: "Quantity",
        data: labels.map((label) => {
          return this.resultCartReturnMap[label]?.quantityCount || 0;
        }),
        borderColor: this.colorMap.green + borderDefaultOpacityLine,
        backgroundColor: this.colorMap.green + backgroundDefaultOpacityLine
      }
    ];

    let xAxisConfig = this.chartUtil.getTimeGroupingXAxisConfig(
      grouping,
      labels,
      xTitle,
      xTooltipFormat
    );

    let chart = this.allCharts["lineitemsQuantityCountChart"];

    if (!chart) {
      chart = new window.Chart(
        this.refs.canvasLineitemsQuantityCount.getContext("2d"),
        {
          type: "bar",
          data: {
            labels,
            datasets: allData
          },
          options: {
            ...this.chartUtil.defaultOptions,
            plugins: {
              title: {
                display: true,
                text: "Line Items and Quantity Count"
              },
              legend: {
                position: "bottom",
                align: "end",
                title: {
                  display: true,
                  text: "Legend"
                }
              }
            },
            scales: {
              x: xAxisConfig,
              y: {
                title: {
                  display: true,
                  text: "Count of line items and quantity"
                },
                beginAtZero: true,
                grace: "5%",
                ticks: {
                  callback: this.chartUtil.formatThousands,
                  count: 11
                }
              }
            },
            interaction: {
              ...this.chartUtil.interactionSettings,
              intersect: true
            }
          },
          plugins: [this.chartUtil.backgroundColorPlugin]
        }
      );
      this.allCharts["lineitemsQuantityCountChart"] = chart;
    } else {
      chart.data.labels = labels;
      chart.data.datasets = allData;
      chart.options.scales.x = xAxisConfig;
    }

    this.tableLineitemsQuantityCount();
  }

  lineItemQtyData;
  tableLineitemsQuantityCount() {
    let labels = [...this.resultLabels];

    let grouping = this.currentGrouping;

    let columns = [
      {
        title: "Total",
        field: "total",
        headerSort: false,
        formatter: this.tableUtil.tableNumberFormatter
      },
      ...this.tableUtil.columnLabelGroupingLogic(labels, grouping)
    ];

    let rowHeader = {
      title: "Count",
      field: "count",
      headerSort: false,
      frozen: true
    };

    let lineItemsRowData = { count: "Line Items" };
    let quantityRowData = { count: "Item Quantity" };

    let totalLineItems = 0;
    let totalQuantity = 0;

    labels.forEach((label) => {
      let cartReturn = this.resultCartReturnMap[label];
      let lineItemCount = cartReturn?.lineItemCount || 0;
      let quantityCount = cartReturn?.quantityCount || 0;

      lineItemsRowData[label] = lineItemCount;
      quantityRowData[label] = quantityCount;

      totalLineItems += lineItemCount;
      totalQuantity += quantityCount;
    });

    lineItemsRowData["total"] = totalLineItems;
    quantityRowData["total"] = totalQuantity;

    let tData = [lineItemsRowData, quantityRowData];
    this.lineItemQtyData = [...tData];

    let table = this.allTables["lineitemsQuantityCountTable"];

    if (!table) {
      table = new window.Tabulator(this.refs.tableLineitemsQuantityCount, {
        columns,
        rowHeader,
        data: tData
      });

      this.allTables["lineitemsQuantityCountTable"] = table;
    } else {
      table.setColumns(columns);
      table.replaceData(tData);
      table.redraw(true);
    }
  }

  tableCustomerLevelOverview() {
    let customers = [...this.resultCustomerList];

    let columns = [
      {
        title: "Total return carts",
        field: "totalReturnCarts",
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      },
      {
        title: "Total",
        columns: []
      },
      {
        title: "Average",
        columns: []
      }
    ];

    let currencies = [...this.resultCustomerCurrencies];
    currencies.forEach((currency) => {
      let colData = {
        title: currency,
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      };
      columns[1].columns.push({ ...colData, field: "total_" + currency });
      columns[2].columns.push({ ...colData, field: "avg_" + currency });
    });

    let rowHeader = {
      title: "Customer",
      field: "customer",
      frozen: true,
      headerSort: true
    };

    let tData = customers.map((customer) => {
      let rowData = {
        customer,
        totalReturnCarts: this.resultCustomerDataMap[customer]?.poomCount || 0
      };

      currencies.forEach((currency) => {
        rowData["total_" + currency] =
          this.resultCustomerDataMap[customer]?.orderTotal[currency] || 0;
        rowData["avg_" + currency] =
          this.resultCustomerDataMap[customer]?.avgOrderTotal[currency] || 0;
      });
      return rowData;
    });

    let table = this.allTables["customerLevelOverviewTable"];
    if (table) {
      table.destroy();
    }

    table = new window.Tabulator(this.refs.tableCustomerLevelOverview, {
      columns,
      rowHeader,
      data: tData,
      initialSort: [
        { column: "totalReturnCarts", dir: "desc" },
        { column: "customer", dir: "asc" }
      ],
      ...this.tableUtil.defaultTablePaginationConfig
    });

    this.allTables["customerLevelOverviewTable"] = table;
  }

  handleChartScroll(e) {
    let chartName = e.target.dataset.chart;
    let chart = this.allCharts[chartName];
    if (chart) {
      chart.options.scales.y.min = e.detail.minY;
      chart.options.scales.y.max = e.detail.maxY;
      chart.update();
    }
  }

  graphCustomerLevelReturnCartCount() {
    if (!this.refs.canvasCustomerLevelReturnCartCount) {
      return;
    }

    let labels = [...this.resultCustomerList];

    const borderDefaultOpacityBar = "CC";
    const backgroundDefaultOpacityBar = "99";

    let sortedData = labels.map((customer) => {
      let poomCount = this.resultCustomerDataMap[customer]?.poomCount || 0;
      let posrCount = this.resultCustomerDataMap[customer]?.posrCount || 0;

      let abandonedCount = Math.max(0, posrCount - poomCount);

      return {
        customer,
        returnData: poomCount,
        abandonedData: abandonedCount,
        totalData: poomCount + abandonedCount
      };
    });

    sortedData.sort((a, b) => {
      return b.totalData - a.totalData;
    });

    let returnData = [];
    let abandonedData = [];
    labels = sortedData.map((data) => {
      returnData.push(data.returnData);
      abandonedData.push(data.abandonedData);
      return data.customer;
    });

    let data = [
      {
        type: "bar",
        label: "Abandoned carts",
        data: abandonedData,
        borderColor: this.colorMap.blue + borderDefaultOpacityBar,
        backgroundColor: this.colorMap.blue + backgroundDefaultOpacityBar
      },
      {
        type: "bar",
        label: "Returned carts",
        data: returnData,
        borderColor: this.colorMap.teal + borderDefaultOpacityBar,
        backgroundColor: this.colorMap.teal + backgroundDefaultOpacityBar
      }
    ];

    let chartName = "customerLevelReturnCartCountChart";
    let chart = this.allCharts[chartName];

    if (!chart) {
      chart = new window.Chart(this.refs.canvasCustomerLevelReturnCartCount, {
        type: "bar",
        data: {
          labels,
          datasets: data
        },
        options: {
          ...this.chartUtil.defaultOptions,
          plugins: {
            tooltip: {
              position: "nearest",
              callbacks: {
                label: (context) => {
                  return (
                    context.dataset.label +
                    ": " +
                    this.chartUtil.formatToolTipNumber.format(context.parsed.x)
                  );
                },
                footer: (tooltipItems) => {
                  let sum = 0;
                  tooltipItems.forEach((item) => {
                    sum += item.parsed.x;
                  });
                  return `Total: ${this.chartUtil.formatToolTipNumber.format(sum)}`;
                }
              }
            },
            title: {
              display: true,
              text: "Customer level return cart count"
            },
            legend: {
              position: "bottom",
              align: "end",
              title: {
                display: true,
                text: "Legend"
              }
            }
          },
          indexAxis: "y",
          scales: {
            x: {
              stacked: true,
              title: {
                display: true,
                text: "Carts"
              },
              beginAtZero: true,
              grace: "5%",
              ticks: {
                callback: this.chartUtil.formatThousands,
                count: 11
              }
            },
            y: {
              stacked: true,
              title: {
                display: true,
                text: "Customers"
              },
              min: 0,
              max: this.customerLevelMaxBars - 1
            }
          },
          interaction: {
            mode: "nearest",
            axis: "y",
            intersect: false
          }
        },
        plugins: [this.chartUtil.backgroundColorPlugin]
      });

      this.allCharts[chartName] = chart;
    } else {
      chart.data.labels = labels;
      chart.data.datasets = data;
      chart.options.scales.y.min = 0;
      chart.options.scales.y.max = this.customerLevelMaxBars - 1;

      this.refs.scrollCustomerLevelReturnCartCount?.resetScroll();
    }

    this.tableCustomerLevelReturnCartCount();
  }

  tableCustomerLevelReturnCartCount() {
    let customers = [...this.resultCustomerList];

    let columns = [
      {
        title: "All",
        field: "all",
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      },
      {
        title: "Return carts",
        field: "return",
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      },
      {
        title: "Percent sessions with return cart",
        field: "pctReturn",
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      },
      {
        title: "Percent abandoned",
        field: "pctAbandoned",
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      }
    ];

    let rowHeader = {
      title: "Customer",
      field: "customer",
      headerSort: true,
      frozen: true
    };

    let tData = customers.map((customer) => {
      let rowData = {
        customer,
        all: this.resultCustomerDataMap[customer]?.posrCount || 0,
        return: this.resultCustomerDataMap[customer]?.poomCount || 0
      };

      let pctReturn = rowData.all
        ? Math.floor((rowData.return / rowData.all) * 100)
        : 0;

      rowData.pctReturn = pctReturn + "%";
      rowData.pctAbandoned = 100 - pctReturn + "%";

      return rowData;
    });

    let tableName = "customerLevelReturnCartCountTable";
    let table = this.allTables[tableName];
    if (!table) {
      table = new window.Tabulator(
        this.refs.tableCustomerLevelReturnCartCount,
        {
          columns,
          rowHeader,
          data: tData,
          initialSort: [
            { column: "all", dir: "desc" },
            { column: "customer", dir: "asc" }
          ],
          ...this.tableUtil.defaultTablePaginationConfig
        }
      );

      this.allTables[tableName] = table;
    } else {
      table.setColumns(columns);
      table.replaceData(tData);
      table.redraw(true);
    }
  }

  graphCustomerLevelLineItemCount() {
    let labels = [...this.resultCustomerList];

    const borderDefaultOpacityBar = "CC";
    const backgroundDefaultOpacityBar = "99";

    let sortedData = labels.map((customer) => {
      return {
        customer,
        lineItemsTotal:
          this.resultCustomerDataMap[customer]?.lineItemsTotal || 0,
        quantityTotal: this.resultCustomerDataMap[customer]?.quantityTotal || 0
      };
    });

    sortedData.sort((a, b) => b.quantityTotal - a.quantityTotal);

    let lineItemsData = [];
    let quantityData = [];
    labels = sortedData.map((item) => {
      lineItemsData.push(item.lineItemsTotal);
      quantityData.push(item.quantityTotal);
      return item.customer;
    });

    let data = [
      {
        type: "bar",
        label: "Item quantity",
        data: quantityData,
        borderColor: this.colorMap.purple + borderDefaultOpacityBar,
        backgroundColor: this.colorMap.purple + backgroundDefaultOpacityBar
      },
      {
        type: "bar",
        label: "Line items",
        data: lineItemsData,
        borderColor: this.colorMap.orange + borderDefaultOpacityBar,
        backgroundColor: this.colorMap.orange + backgroundDefaultOpacityBar
      }
    ];

    let chartName = "customerLevelLineItemCountChart";
    let chart = this.allCharts[chartName];
    if (!chart) {
      chart = new window.Chart(this.refs.canvasCustomerLevelLineItemCount, {
        type: "bar",
        data: {
          labels,
          datasets: data
        },
        options: {
          ...this.chartUtil.defaultOptions,
          plugins: {
            tooltip: {
              position: "nearest",
              callbacks: {
                label: (context) => {
                  return (
                    context.dataset.label +
                    ": " +
                    this.chartUtil.formatToolTipNumber.format(context.parsed.x)
                  );
                }
              }
            },
            title: {
              display: true,
              text: "Line Items and Quantity Count"
            },
            legend: {
              position: "bottom",
              align: "end",
              title: {
                display: true,
                text: "Legend"
              }
            }
          },
          indexAxis: "y",
          scales: {
            x: {
              title: {
                display: true,
                text: "Count"
              },
              beginAtZero: true,
              grace: "5%",
              ticks: {
                callback: this.chartUtil.formatThousands,
                count: 11
              }
            },
            y: {
              title: {
                display: true,
                text: "Customers"
              },
              min: 0,
              max: this.customerLevelMaxBars - 1
            }
          },
          interaction: {
            ...this.chartUtil.interactionSettings,
            intersect: true
          }
        },
        plugins: [this.chartUtil.backgroundColorPlugin]
      });

      this.allCharts[chartName] = chart;
    } else {
      chart.data.labels = labels;
      chart.data.datasets = data;
      chart.options.scales.y.min = 0;
      chart.options.scales.y.max = this.customerLevelMaxBars - 1;

      this.refs.scrollCustomerLevelLineItemsQuantityCount?.resetScroll();
    }

    this.tableCustomerLevelLineItemsQuantityCount();
  }

  tableCustomerLevelLineItemsQuantityCount() {
    let customers = [...this.resultCustomerList];

    let columns = [
      {
        title: "Item quantity",
        field: "itemQuantity",
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      },
      {
        title: "Line items",
        field: "lineItems",
        headerSort: true,
        formatter: this.tableUtil.tableNumberFormatter
      }
    ];

    let rowHeader = {
      title: "Customer",
      field: "customer",
      headerSort: true,
      frozen: true
    };

    let tData = customers.map((customer) => {
      return {
        customer,
        itemQuantity: this.resultCustomerDataMap[customer]?.quantityTotal || 0,
        lineItems: this.resultCustomerDataMap[customer]?.lineItemsTotal || 0
      };
    });

    let tableName = "customerLevelLineItemsQuantityCount";
    let table = this.allTables[tableName];
    if (!table) {
      table = new window.Tabulator(
        this.refs.tableCustomerLevelLineItemsQuantityCount,
        {
          columns,
          rowHeader,
          data: tData,
          initialSort: [
            { column: "itemQuantity", dir: "desc" },
            { column: "lineItems", dir: "desc" },
            { column: "customer", dir: "asc" }
          ],
          ...this.tableUtil.defaultTablePaginationConfig
        }
      );

      this.allTables[tableName] = table;
    } else {
      table.setColumns(columns);
      table.replaceData(tData);
      table.redraw(true);
    }
  }

  tableOverallData() {
    let labels = [...this.resultLabels];
    let grouping = this.currentGrouping;

    let columns = [
      {
        title: "Total",
        field: "total",
        formatter: this.tableUtil.tableNumberFormatter
      },
      ...this.tableUtil.columnLabelGroupingLogic(labels, grouping)
    ];

    let defaultBlanks = {};
    columns.forEach((col) => {
      col.accessorDownload = this.blankAccessor;
      defaultBlanks[col.field] = this.blankPlaceholder;
    });

    let rowHeader = {
      title: "Parameter",
      field: "parameter",
      headerSort: false,
      frozen: true
    };

    let totalData = this.returnCartTotalData.map((row) => {
      row.total = row.valuePoint;
      row.parameter = row.currency;
      return row;
    });
    let avgData = this.returnCartAverageData.map((row) => {
      row.total = row.valuePoint;
      row.parameter = row.currency;
      return row;
    });
    let returnCount = this.returnCartCountData.map((row) => {
      row.parameter = row.sessions;
      return row;
    });
    let lineItemsQty = this.lineItemQtyData.map((row) => {
      row.parameter = row.count;
      return row;
    });

    let tData = [
      {
        ...defaultBlanks,
        parameter: "Value",
        _children: [
          {
            ...defaultBlanks,
            parameter: "Totals",
            _children: totalData
          },
          {
            ...defaultBlanks,
            parameter: "Average",
            _children: avgData
          }
        ]
      },
      {
        ...defaultBlanks,
        parameter: "Sessions",
        _children: returnCount
      },
      {
        ...defaultBlanks,
        parameter: "Items",
        _children: lineItemsQty
      }
    ];

    let tableName = "overallDataTable";
    let table = this.allTables[tableName];

    if (!table) {
      table = new window.Tabulator(this.refs.tableOverallData, {
        columns,
        rowHeader,
        dataTree: true,
        data: tData,
        downloadConfig: {
          dataTree: true
        }
      });

      const rowExpandCollapse = (row, level) => {
        table.redraw(true);
      };

      table.on("dataTreeRowExpanded", rowExpandCollapse);

      table.on("dataTreeRowCollapsed", rowExpandCollapse);

      this.allTables[tableName] = table;
    } else {
      table.setColumns(columns);
      table.replaceData(tData);
      table.redraw(true);
    }
  }
}