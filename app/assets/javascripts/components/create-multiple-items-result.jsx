;(() => {
  // NOTE: only for linter and clarity:
  /* global React */
  /* global _jed */

  const f = window.lodash

  const TABLE_CELL_BORDER = '1px solid lightgray'
  const TABLE_CELL_STYLE = {
    padding: '0.25rem 0.5rem',
    verticalAlign: 'bottom',
    border: TABLE_CELL_BORDER
  }

  window.CreateMultipleItemsResult = window.createReactClass({
    propTypes: {},

    getInitialState() {
      return {
        showBarcodes: false,
        showFullURLs: false
      }
    },

    render({ props } = this) {
      const { items, date, menu, csv_url, csv_filename } = props
      const pool = items[0].inventory_pool
      const model = items[0].model
      // FIXME: get from server, add return_url param
      const modelLink = `/manage/${pool.id}/models/${model.id}/edit`
      const tdProps = {
        style: {
          padding: '0.25rem 0.5rem',
          verticalAlign: 'bottom',
          border: TABLE_CELL_BORDER
        }
      }

      return (
        <div className="row content-wrapper min-height-xl min-width-full straight-top">
          <div className="margin-top-l padding-horizontal-m">
            <div className="row">
              <div className="col2of3">
                <h1 className="headline-xl">{_jed('create_multiple_items_head_title')}</h1>
              </div>
              <div className="col1of3">
                <div className="text-align-right">
                  <InventoryDropdown menu={menu} />
                </div>
              </div>
            </div>
          </div>

          <div className="font-size-m padding-horizontal-m margin-top-l">
            <h3 className="headline-m padding-bottom-s">
              {_jed('create_multiple_items_head_summary')}
            </h3>
            <div>
              <table>
                <tbody>
                  <tr>
                    <td {...tdProps}>{_jed('create_multiple_items_label_quantity')}</td>
                    <td {...tdProps}>{items.length}</td>
                  </tr>
                  <tr>
                    <td {...tdProps}>{_jed('Model')}</td>
                    <td {...tdProps}>
                      {/* eslint-disable-next-line react/jsx-no-target-blank */}
                      <a target="_blank" href={modelLink}>
                        {model.product} {model.version}
                      </a>
                    </td>
                  </tr>
                  <tr>
                    <td {...tdProps}>{_jed('create_multiple_items_label_date')}</td>
                    <td {...tdProps}>{date}</td>
                  </tr>
                  <tr>
                    <td {...tdProps}>{_jed('create_multiple_items_label_export')}</td>
                    <td {...tdProps}>
                      {/* eslint-disable-next-line react/jsx-no-target-blank */}
                      <a
                        className="button small white"
                        style={{ height: '2.2em', fontSize: '0.9em' }}
                        href={csv_url}
                        download={csv_filename}
                        target="_blank">
                        {_jed('create_multiple_items_btn_csv_export')}
                      </a>{' '}
                      {_jed('create_multiple_items_hint_csv_export')}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div className="padding-vertical-m">
              <h3 className="headline-m padding-bottom-s">
                {_jed('create_multiple_items_head_list')}
              </h3>

              <div>
                <label>
                  <input
                    type="checkbox"
                    checked={this.state.showBarcodes}
                    onChange={(e) => this.setState({ showBarcodes: e.target.checked })}
                  />{' '}
                  {_jed('create_multiple_items_checkbox_show_barcode')}
                </label>
              </div>
              <div className="margin-bottom-s">
                <label>
                  <input
                    type="checkbox"
                    checked={this.state.showFullURLs}
                    onChange={(e) => this.setState({ showFullURLs: e.target.checked })}
                  />{' '}
                  {_jed('create_multiple_items_checkbox_show_full_urls')}
                </label>
              </div>

              <ItemsTable
                items={items}
                showBarcodes={this.state.showBarcodes}
                showFullURLs={this.state.showFullURLs}
              />
            </div>
          </div>

          <pre className="hidden">{JSON.stringify(props, 0, 2)}</pre>
        </div>
      )
    }
  })

  window.CreateMultipleItemsResult.displayName = 'CreateMultipleItemsResult'

  const ItemsTable = ({ items, showBarcodes = true, showFullURLs = false }) => {
    const tdProps = {
      style: { ...TABLE_CELL_STYLE, verticalAlign: showBarcodes ? 'middle' : 'bottom' }
    }
    return (
      <table
        className="width-full font-size-m"
        style={{ fontFamily: 'monospace', border: TABLE_CELL_BORDER, textAlign: 'center' }}>
        <thead>
          <tr>
            <th {...tdProps}>#</th>
            <th {...tdProps}>{_jed('Inventory code')}</th>
            <th {...tdProps}>UUID/URL</th>
          </tr>
        </thead>
        <tbody>
          {f.map(items, (itm, ix) => {
            return (
              <tr key={ix} className="padding-bottom-s">
                <th {...tdProps} scrope="row">
                  {ix + 1}
                </th>
                {!showBarcodes ? (
                  <td {...tdProps}>{itm.inventory_code}</td>
                ) : (
                  <td style={{ ...TABLE_CELL_STYLE, padding: 0, textAlign: 'center' }}>
                    <img src={itm.barcode} />
                    <span style={{ display: 'block', margin: '-0.5rem 0 0.5rem' }}>
                      {itm.inventory_code}
                    </span>
                  </td>
                )}
                <td {...tdProps}>
                  {/* eslint-disable-next-line react/jsx-no-target-blank */}
                  <a target="_blank" href={itm.url}>
                    {showFullURLs && itm.url ? itm.url : itm.id}
                  </a>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    )
  }

  const InventoryDropdown = ({ menu }) => {
    const spaced = (str) => ` ${str} `
    return (
      <div className="dropdown-holder inline-block">
        <div className="button white dropdown-toggle">
          {spaced(_jed('Add inventory'))}
          <div className="arrow down"></div>
        </div>
        <ul className="dropdown right" style={{ display: 'none' }}>
          <li>
            <a className="dropdown-item" href={menu.create_model_url}>
              {spaced(_jed('Model'))}
            </a>
          </li>
          <li>
            <a className="dropdown-item" href={menu.create_package_url}>
              {spaced(_jed('Package'))}
            </a>
          </li>
          <li>
            <a className="dropdown-item" href={menu.create_item_url}>
              {spaced(_jed('Item'))}
            </a>
          </li>
          <li>
            <a className="dropdown-item" href={menu.create_option_url}>
              {spaced(_jed('Option'))}
            </a>
          </li>
          <li>
            <a className="dropdown-item" href={menu.create_software_url}>
              {spaced(_jed('Software'))}
            </a>
          </li>
          <li>
            <a className="dropdown-item" href={menu.create_license_url}>
              {spaced(_jed('Software License'))}
            </a>
          </li>
        </ul>
      </div>
    )
  }
})()
