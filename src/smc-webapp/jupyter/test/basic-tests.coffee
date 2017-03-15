###
Just run some very basic startup tests.
###

actions = store = undefined
setup = (cb) -> (require('./setup').setup (err, x) -> actions=x; store=x?.store; cb(err))
{teardown} = require('./setup')

expect  = require('expect')

describe 'tests the setup code -- ', ->
    before(setup)
    after(teardown)

    it 'sets something in the store', ->
        actions.setState(test:'value')
        expect(store.get('test')).toBe('value')

    it 'checks the mode got set', ->
        expect(store.get('mode')).toBe('escape')

    it 'checks there is exactly one cell', ->
        expect(store.get('cells').size).toBe(1)

    it 'checks that cell_list has size 1', ->
        expect(store.get('cell_list').size).toBe(1)

    it 'checks that cur_id is the initial cell', ->
        expect(store.get('cur_id')).toEqual(store.get('cell_list').get(0))

    it 'inserts a cell and sees that there are now 2', ->
        actions.insert_cell(1)
        expect(store.get('cells').size).toBe(2)

describe 'test cursors positions -- ', ->
    before(setup)
    after(teardown)

    list = undefined
    it 'inserts a cell', ->
        actions.insert_cell(1)
        list = store.get('cell_list').toJS()
        expect(list.length).toBe(2)

    it 'sets cursor locs', (done) ->
        actions.set_cur_id(list[0])
        actions.set_mode('edit')
        actions.syncdb.once 'cursor_activity', ->
            c = store.get_cursors().toJS()
            client_id = global.salvus_client._client_id
            expect(c[client_id].locs).toEqual([ { id: list[0], x: 0, y: 0 }, { id: list[0], x: 2, y: 1 } ])
            done()
        # hack so cursor saving enabled (add two fake users...)
        actions.syncdb._doc._users.push(actions.syncdb._doc._users[0])
        actions.syncdb._doc._users.push(actions.syncdb._doc._users[0])
        actions.set_cursor_locs([{id:list[0], x:0, y:0}, {id:list[0], x:2, y:1}])
