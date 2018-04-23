window.leihsAjax = {


  getAjax(url, data, callback) {
    $.ajax({
      url: url,
      contentType: 'application/json',
      dataType: 'json',
      method: 'GET',
      data: data
    }).done((data) => {
      callback('success', data)

    }).error((data) => {
      callback('error', data)
    })
  },


  putAjax(url, data, callback) {


    $.ajax({
      url: url,
      data: JSON.stringify(data),
      contentType: 'application/json',
      dataType: 'json',
      method: 'PUT'
    }).done((data) => {
      callback('success', data)
    }).error((data) => {
      callback('error', data)

    })


  }

}
