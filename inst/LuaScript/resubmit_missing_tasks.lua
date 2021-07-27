local publicTaskQueue = KEYS[1]
local managerTaskSet = KEYS[2]
local managerResultQueue = KEYS[3]
local liveWorkers = ARGV

local missingWorker = {}
local waitingTask = redis.call("SMEMBERS", managerTaskSet)
local publicTasks = nil
for i = 1, #waitingTask, 1 do
    local taskId = waitingTask[i]
    local existsTask = redis.call("exists", taskId)
    if existsTask == 1 then
        local workerId = redis.call("lrange", taskId, taskWorkerIdx, taskWorkerIdx)[1]
        local missing = false
        if (workerId ~= "public") and (not existsElement(liveWorkers, workerId)) then
            missing = true
        end
        if workerId == "public" then
            if publicTasks == nil then
                publicTasks = redis.call("lrange", publicTaskQueue, 0, -1)
            end
            if not existsElement(publicTasks, taskId) then
                missing = true
            end
        end
        if missing then
            table.insert(missingWorker, workerId)
            redis.call('lset', taskId, 2, "public")
            redis.call("rpush", publicTaskQueue, taskId)
        end
    end
end

local waitingTaskNum = #waitingTask
local resultNum = redis.call("llen", managerResultQueue)

return {missingWorker, waitingTaskNum + resultNum}
