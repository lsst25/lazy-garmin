// Usage: mtpsend <local file> <parent folder id> <remote name>
#include <libmtp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "usage: %s <file> <folder-id> <name>\n", argv[0]); return 2; }
    struct stat st; if (stat(argv[1], &st) != 0) { perror("stat"); return 1; }
    LIBMTP_Init();
    LIBMTP_raw_device_t *raw = NULL; int count = 0;
    if (LIBMTP_Detect_Raw_Devices(&raw, &count) != 0 || count == 0) { fprintf(stderr, "no MTP device\n"); return 1; }
    // Uncached, so the folder listing below is allowed.
    LIBMTP_mtpdevice_t *dev = LIBMTP_Open_Raw_Device_Uncached(&raw[0]);
    free(raw);
    if (!dev) { fprintf(stderr, "could not open MTP device\n"); return 1; }
    LIBMTP_Get_Storage(dev, LIBMTP_STORAGE_SORTBY_NOTSORTED);
    uint32_t parent = (uint32_t)strtoul(argv[2], NULL, 10);
    // No need to delete an old copy: the watch replaces a file with the same name.
    LIBMTP_file_t *f = LIBMTP_new_file_t();
    f->filename = strdup(argv[3]); f->filesize = st.st_size; f->filetype = LIBMTP_FILETYPE_UNKNOWN;
    f->parent_id = parent; f->storage_id = dev->storage->id;
    int r = LIBMTP_Send_File_From_File(dev, argv[1], f, NULL, NULL);
    if (r != 0) { LIBMTP_Dump_Errorstack(dev); fprintf(stderr, "send failed\n"); }
    else printf("sent %s (%lld bytes) as id %u\n", argv[3], (long long)st.st_size, f->item_id);
    LIBMTP_destroy_file_t(f); LIBMTP_Release_Device(dev);
    return r != 0;
}
