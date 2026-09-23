/*
 * D2Stats.Core — process memory helper (ABI 1)
 *
 * Rarely rebuilt. D2Stats.exe talks to this process over a named pipe and
 * never calls OpenProcess / ReadProcessMemory / WriteProcessMemory /
 * VirtualAllocEx / CreateRemoteThread itself.
 *
 * Pipe: \\.\pipe\D2StatsCore-<parentPid>
 * Lifetime: exits when the parent GUI process dies or the pipe closes.
 */

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define CORE_ABI 1u
#define CORE_MAGIC 0x43324432u /* 'D2C' */
#define MAX_PAYLOAD (256u * 1024u)

#define CMD_GET_ABI 1u
#define CMD_PING 2u
#define CMD_ATTACH 3u
#define CMD_CLOSE 4u
#define CMD_READ 5u
#define CMD_WRITE 6u
#define CMD_ALLOC 7u
#define CMD_FREE 8u
#define CMD_REMOTE_THREAD 9u

#define ST_OK 0u
#define ST_ERR 1u

#pragma pack(push, 1)
typedef struct {
    uint32_t magic;
    uint32_t cmd;
    uint32_t size;
} ReqHdr;

typedef struct {
    uint32_t magic;
    uint32_t status;
    uint32_t size;
} RespHdr;
#pragma pack(pop)

static HANDLE g_game = NULL;
static HANDLE g_parent = NULL;
static HANDLE g_pipe = NULL;

static BOOL EnableDebugPrivilege(void)
{
    HANDLE token = NULL;
    TOKEN_PRIVILEGES tp;
    LUID luid;

    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &token))
        return FALSE;
    if (!LookupPrivilegeValueA(NULL, "SeDebugPrivilege", &luid)) {
        CloseHandle(token);
        return FALSE;
    }
    tp.PrivilegeCount = 1;
    tp.Privileges[0].Luid = luid;
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    AdjustTokenPrivileges(token, FALSE, &tp, sizeof(tp), NULL, NULL);
    CloseHandle(token);
    return TRUE;
}

static BOOL ReadExact(HANDLE h, void *buf, uint32_t size)
{
    uint8_t *p = (uint8_t *)buf;
    uint32_t got_total = 0;
    while (got_total < size) {
        DWORD n = 0;
        if (!ReadFile(h, p + got_total, size - got_total, &n, NULL) || n == 0)
            return FALSE;
        got_total += n;
    }
    return TRUE;
}

static BOOL WriteExact(HANDLE h, const void *buf, uint32_t size)
{
    const uint8_t *p = (const uint8_t *)buf;
    uint32_t put_total = 0;
    while (put_total < size) {
        DWORD n = 0;
        if (!WriteFile(h, p + put_total, size - put_total, &n, NULL) || n == 0)
            return FALSE;
        put_total += n;
    }
    return TRUE;
}

static BOOL SendResp(uint32_t status, const void *payload, uint32_t size)
{
    RespHdr hdr;
    hdr.magic = CORE_MAGIC;
    hdr.status = status;
    hdr.size = size;
    if (!WriteExact(g_pipe, &hdr, sizeof(hdr)))
        return FALSE;
    if (size && payload)
        return WriteExact(g_pipe, payload, size);
    return TRUE;
}

static BOOL SendOk(const void *payload, uint32_t size)
{
    return SendResp(ST_OK, payload, size);
}

static BOOL SendErr(void)
{
    return SendResp(ST_ERR, NULL, 0);
}

static DWORD WINAPI ParentWatch(LPVOID param)
{
    (void)param;
    WaitForSingleObject(g_parent, INFINITE);
    ExitProcess(0);
    return 0;
}

static void CloseGame(void)
{
    if (g_game) {
        CloseHandle(g_game);
        g_game = NULL;
    }
}

static BOOL HandleRequest(const ReqHdr *req, uint8_t *payload)
{
    switch (req->cmd) {
    case CMD_GET_ABI: {
        uint32_t abi = CORE_ABI;
        return SendOk(&abi, sizeof(abi));
    }
    case CMD_PING:
        return SendOk(NULL, 0);

    case CMD_ATTACH: {
        uint32_t pid;
        HANDLE proc;
        if (req->size < 4)
            return SendErr();
        memcpy(&pid, payload, 4);
        CloseGame();
        proc = OpenProcess(
            PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION |
                PROCESS_VM_READ | PROCESS_VM_WRITE | SYNCHRONIZE,
            FALSE,
            pid);
        if (!proc)
            return SendErr();
        g_game = proc;
        return SendOk(NULL, 0);
    }

    case CMD_CLOSE:
        CloseGame();
        return SendOk(NULL, 0);

    case CMD_READ: {
        uint32_t addr, size;
        SIZE_T nread = 0;
        static uint8_t out[MAX_PAYLOAD];
        if (req->size < 8 || !g_game)
            return SendErr();
        memcpy(&addr, payload, 4);
        memcpy(&size, payload + 4, 4);
        if (size == 0 || size > MAX_PAYLOAD)
            return SendErr();
        if (!ReadProcessMemory(g_game, (LPCVOID)(uintptr_t)addr, out, size, &nread) || nread != size)
            return SendErr();
        return SendOk(out, size);
    }

    case CMD_WRITE: {
        uint32_t addr, size;
        SIZE_T nwritten = 0;
        if (req->size < 8 || !g_game)
            return SendErr();
        memcpy(&addr, payload, 4);
        memcpy(&size, payload + 4, 4);
        if (size == 0 || size > MAX_PAYLOAD || req->size < 8 + size)
            return SendErr();
        if (!WriteProcessMemory(g_game, (LPVOID)(uintptr_t)addr, payload + 8, size, &nwritten) || nwritten != size)
            return SendErr();
        return SendOk(NULL, 0);
    }

    case CMD_ALLOC: {
        uint32_t size, alloc_type, protect;
        LPVOID p;
        uint32_t addr;
        if (req->size < 12 || !g_game)
            return SendErr();
        memcpy(&size, payload, 4);
        memcpy(&alloc_type, payload + 4, 4);
        memcpy(&protect, payload + 8, 4);
        p = VirtualAllocEx(g_game, NULL, size, alloc_type, protect);
        if (!p)
            return SendErr();
        addr = (uint32_t)(uintptr_t)p;
        return SendOk(&addr, sizeof(addr));
    }

    case CMD_FREE: {
        uint32_t addr, size, free_type;
        SIZE_T free_size;
        if (req->size < 12 || !g_game)
            return SendErr();
        memcpy(&addr, payload, 4);
        memcpy(&size, payload + 4, 4);
        memcpy(&free_type, payload + 8, 4);
        /* MEM_RELEASE (0x8000) requires size 0 */
        free_size = (free_type & 0x8000u) ? 0 : size;
        if (!VirtualFreeEx(g_game, (LPVOID)(uintptr_t)addr, free_size, free_type))
            return SendErr();
        return SendOk(NULL, 0);
    }

    case CMD_REMOTE_THREAD: {
        uint32_t func, arg, exit_code;
        HANDLE thread;
        DWORD code = 0;
        if (req->size < 8 || !g_game)
            return SendErr();
        memcpy(&func, payload, 4);
        memcpy(&arg, payload + 4, 4);
        thread = CreateRemoteThread(
            g_game, NULL, 0, (LPTHREAD_START_ROUTINE)(uintptr_t)func, (LPVOID)(uintptr_t)arg, 0, NULL);
        if (!thread)
            return SendErr();
        WaitForSingleObject(thread, INFINITE);
        GetExitCodeThread(thread, &code);
        CloseHandle(thread);
        exit_code = (uint32_t)code;
        return SendOk(&exit_code, sizeof(exit_code));
    }

    default:
        return SendErr();
    }
}

int WINAPI WinMain(HINSTANCE hi, HINSTANCE hp, LPSTR cmd, int show)
{
    DWORD parent_pid;
    char pipe_name[64];
    uint8_t *payload;
    ULONG client_pid;

    (void)hi;
    (void)hp;
    (void)show;

    parent_pid = (DWORD)strtoul(cmd ? cmd : "", NULL, 10);
    if (parent_pid == 0)
        return 1;

    EnableDebugPrivilege();

    g_parent = OpenProcess(SYNCHRONIZE, FALSE, parent_pid);
    if (!g_parent)
        return 1;

    if (!CreateThread(NULL, 0, ParentWatch, NULL, 0, NULL))
        return 1;

    wsprintfA(pipe_name, "\\\\.\\pipe\\D2StatsCore-%u", (unsigned)parent_pid);
    g_pipe = CreateNamedPipeA(
        pipe_name,
        PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
        1,
        MAX_PAYLOAD + 64,
        MAX_PAYLOAD + 64,
        0,
        NULL);
    if (g_pipe == INVALID_HANDLE_VALUE)
        return 1;

    if (!ConnectNamedPipe(g_pipe, NULL) && GetLastError() != ERROR_PIPE_CONNECTED)
        return 1;

    client_pid = 0;
    if (GetNamedPipeClientProcessId(g_pipe, &client_pid) && client_pid != parent_pid)
        return 1;

    payload = (uint8_t *)VirtualAlloc(NULL, MAX_PAYLOAD, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!payload)
        return 1;

    for (;;) {
        ReqHdr req;
        if (!ReadExact(g_pipe, &req, sizeof(req)))
            break;
        if (req.magic != CORE_MAGIC || req.size > MAX_PAYLOAD)
            break;
        if (req.size && !ReadExact(g_pipe, payload, req.size))
            break;
        if (!HandleRequest(&req, payload))
            break;
    }

    CloseGame();
    return 0;
}
