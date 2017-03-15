###
Jupyter Notebook

CoCalc: Collaborative web-based calculation
Copyright (C) 2017, Sagemath Inc.

AGPLv3
###

require('coffee-cache').setCacheDir("#{process.env.HOME}/.coffee/cache")

misc = require('smc-util/misc')
smc_react = require('../../smc-react')
require('../../project_store')  # needed so that project store is available.

project_id = '197cebae-6410-469a-8299-54498e438f51'
path       = 'path.ipynb'
redux_name = smc_react.redux_name(project_id, path)

exports.setup = (cb) ->
    # ensure project store is initialized, so can test file menu.
    smc_react.redux.constructor()  # this instantly resets the state of all redux
    smc_react.redux.getProjectStore(project_id)

    # Initialize/reset the testing client that the synctables connect to.
    {salvus_client} = require('../../salvus_client')
    global.salvus_client = salvus_client
    salvus_client.reset()

    # initialize actions/store
    actions = new (require('../actions').JupyterActions)(redux_name, smc_react.redux)
    store   = new (require('../store').JupyterStore)(redux_name, smc_react.redux)
    actions.store = store
    actions._init(project_id, path)

    syncdb = salvus_client.sync_db
        project_id      : project_id
        path            : misc.meta_file(path, 'cocalc')  # TODO
        change_throttle : 0
        save_interval   : 0
        primary_keys    : ['type', 'id']
        string_cols     : ['input']
        cursors         : true

    actions.syncdb = syncdb
    store.syncdb   = syncdb


    syncdb.once 'init', (err) =>
        if err
            cb(err)
        else
            syncdb.on('change', actions._syncdb_change)
            actions._syncdb_change()
            cb(undefined, actions)

    # Cause the syncstring to be initialized so that the above 'init' happens.
    salvus_client.user_query
        query :
            syncstrings :
                project_id : project_id
                path       : misc.meta_file(path, 'cocalc')
                init       : {time: new Date()}

exports.teardown = (cb) ->
    smc_react.redux.getActions(redux_name)?.close()
    smc_react.redux.removeProjectReferences(project_id)
    smc_react.redux.constructor()  # this instantly resets the state of all redux
    salvus_client.reset()
    cb()