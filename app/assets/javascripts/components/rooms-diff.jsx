(() => {
  const React = window.React

  window.RoomsDiff = window.createReactClass({
    propTypes: {
    },

    render () {
      return (

        <div className='wrapper margin-top-m' id='daily-view'>
          <div className='row'>
            <nav>
              <ul>
                <li>
                  <a className='active float-left margin-right-xxs navigation-tab-item padding-horizontal-m'>
                    Rooms Diff
                  </a>
                </li>
              </ul>
            </nav>
          </div>
          <div className='row content-wrapper min-height-xl min-width-full straight-top'>

            <div className='margin-top-l padding-horizontal-m'>
              <div className='row'>
                <h1 className='headline-xl'>CSV import</h1>
              </div>
            </div>


            <div className='row margin-top-l padding-horizontal-l'>
              <div className='row'>
                <h2>Laden Sie eine Komma-separierte CSV-Datei hoch (UTF-8 Kodierung).</h2>
              </div>
              <div className='row margin-vertical-l'>
                <div className='col2of3'>
                  <h3>
                    Akzeptierte Spalten:
                  </h3>
                  <ul style={{listStyleType: 'disc', margin: '1.5em'}}>
                    <li>
                      <b>
                      Liegenschaft
                      (zwingend)
                      </b>
                    </li>
                    <li>
                      <b>
                      Raumnummer
                      (zwingend)
                      </b>
                    </li>
                  </ul>
                  <h3>
                    Alle weiteren Kolonnen werden ignoriert.
                  </h3>
                </div>
                <div className='col1of3'>
                  <form encType='multipart/form-data' action='/manage/rooms_diff' acceptCharset='UTF-8' method='post'>
                    <input name='utf8' type='hidden' value='✓' />
                    <input type='hidden' name='authenticity_token' value={$('meta[name="csrf-token"]').attr('content')} />
                    <div className='row'>
                      <input type='file' name='csv_file' id='csv_file' />
                    </div>
                    <div className='row padding-top-l'>
                      <button className='button green'>
                        Import
                        <i className='fa fa-share-alt'></i>
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            </div>

          </div>
        </div>
      )
    }
  })
})()
