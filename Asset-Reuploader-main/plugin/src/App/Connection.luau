--!strict
local Connection = {}

local HttpService = game:GetService("HttpService")

type Connection = {
    _port: number,
    _thread: thread,

	onDisconnect: () -> ()?,
	onDataRecieved: (data: string) -> ()?,

	Send: (self: Connection, JSON: string) -> (boolean, string),
    Destroy: (self: Connection) -> (),
}

local function get(port: number): string
    return HttpService:GetAsync(`http://localhost:{port}`)
end

local function post(port: number, path: string, data: string): string
    return HttpService:PostAsync(`http://localhost:{port}{path}`, data)
end

local function checkServerStatus(self: Connection)
    local connected, data = pcall(get, self._port)
    if not connected then
        if self.onDisconnect then self.onDisconnect() end
        self:Destroy()
        return
    end

    if self.onDataRecieved then self.onDataRecieved(data :: string) end
    self._thread = task.delay(1, checkServerStatus, self)
end

function Connection.new(port: number): (Connection, string?)
    local connected, data = pcall(get :: any, port)
	assert(connected, "Unable to connect to localhost")
	
    local connection: Connection; connection = {
        _port = port,
        _thread = task.delay(1, checkServerStatus, connection)
    } :: Connection

    function connection.Send(self: Connection, JSON: string): (boolean, string)
        return pcall(post, self._port, "/upload", JSON)
    end

	function connection.Destroy(self: Connection)
		coroutine.yield(self._thread)
		coroutine.close(self._thread)
        table.clear(self :: any)
	end

	return connection, data ~= "null\n" and (data :: string) or nil
end

return Connection
