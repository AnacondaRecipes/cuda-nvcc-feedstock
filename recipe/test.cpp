#include <cuda_runtime.h>
#include <thrust/version.h>

int main() {
    int device_count = 0;
    // Force compile/link validation of cudart_static.lib; the return value is
    // intentionally ignored because this does not test runtime GPU availability.
    (void)cudaGetDeviceCount(&device_count);
    return 0;
}
