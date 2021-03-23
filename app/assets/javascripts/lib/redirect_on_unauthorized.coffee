###

  Redirect on unauthorized

  redirect the browser when a ajax request returns an error (401 / unauthorized)

###

jQuery ->
  $(document).on "ajaxError", (e, xhr)->
    if xhr.status is 401
      # NOTE: maybe show an alert before redirect? may break some tests…
      # alert("You need to login again!")
      console.warn("Need to login again!")
      return_to_path = window.location.pathname + window.location.search
      window.location = ("/sign-in?return-to=" + encodeURIComponent(return_to_path))