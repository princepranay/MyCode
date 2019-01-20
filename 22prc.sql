/* Formatted on 11/22/2018 12:46:56 AM (QP5 v5.256.13226.35510) */
DECLARE
   l_count                       NUMBER;
   l_record_exists               NUMBER;
   L_EXISTS                      NUMBER;
   j                             NUMBER;

   CURSOR c_crossdock_update_item_recs
   IS
      SELECT KEY1 ORGANIZATION_CODE,
             KEY2 LOCATION_CODE,
             KEY3 ITEM_number,
             KEY5 SUPPLIER_NUMBER_SITE,
             (SUBSTR ( (KEY5), 1, ( (INSTR ( (KEY5), '-')) - 1)))
                VENDOR_NUMBER,
             (SUBSTR ( (KEY5), ( (INSTR ( (KEY5), '-')) + 1)))
                VENDOR_SITE_CODE,
             ENABLED_fLAG
        FROM XXC07886_LOOKUPS
       WHERE     (LOOKUP_TYPE LIKE 'XXC7904_ITEM_ATTRIBUTES')
             AND key3 <> 'RECEIPT_ROUTING'
             AND key4 = 'CROSSDOCK'
             AND KEY5 NOT LIKE '%ALL%';

   TYPE type_crossdock_item_update
      IS TABLE OF c_crossdock_update_item_recs%ROWTYPE
      INDEX BY PLS_INTEGER;

   l_crossdock_update_item_tbl   type_crossdock_item_update;
BEGIN
   l_count := 0;
   l_crossdock_update_item_tbl.DELETE;

   OPEN c_crossdock_update_item_recs;

   FETCH c_crossdock_update_item_recs
      BULK COLLECT INTO l_crossdock_update_item_tbl;

   CLOSE c_crossdock_update_item_recs;



   IF l_crossdock_update_item_tbl.COUNT > 0
   THEN
      l_count := 0;
      j := 0;

      FOR i IN l_crossdock_update_item_tbl.FIRST ..
               l_crossdock_update_item_tbl.LAST
      LOOP
         BEGIN
              SELECT COUNT (1)
                INTO L_COUNT
                FROM po_line_locations_all POLL,
                     HR_LOCATIONS HL,
                     PO_HEADERS_ALL POH,
                     PO_LINES_ALL POL,
                     AP_SUPPLIERS APS,
                     AP_SUPPLIER_SITES_ALL ASITE,
                     mtl_system_items_b msib,
                     ORG_ORGANIZATION_DEFINITIONS OOD,
                     RCV_ROUTING_HEADERS rrh
               WHERE     1 = 1
                     AND HL.SHIP_TO_LOCATION_ID = POLL.SHIP_TO_LOCATION_ID
                     AND POL.PO_LINE_ID = POLL.PO_LINE_ID
                     AND msib.inventory_item_id = pol.item_id
                     AND msib.organization_id = poll.ship_to_organization_id
                     AND OOD.ORGANIZATION_ID = POLL.SHIP_TO_ORGANIZATION_ID
                     AND POH.PO_HEADER_ID = POL.PO_HEADER_ID
                     AND POH.PO_HEADER_ID = POLL.PO_HEADER_ID
                     AND POH.VENDOR_ID = APS.VENDOR_ID
                     AND POH.VENDOR_SITE_ID = ASITE.VENDOR_SITE_ID
                     AND APS.VENDOR_ID = ASITE.VENDOR_ID
                     AND POLL.CLOSED_CODE = 'OPEN'
                     AND POLL.ATTRIBUTE1 = 'Inspection Required'
                     AND POLL.RECEIVING_ROUTING_ID = rrh.ROUTING_HEADER_ID
                     AND rrh.routing_name = 'Standard Receipt'
                     AND OOD.ORGANIZATION_CODE =
                            l_crossdock_update_item_tbl (i).ORGANIZATION_CODE
                     AND HL.LOCATION_CODE =
                            l_crossdock_update_item_tbl (i).LOCATION_CODE
                     AND msib.segment1 =
                            l_crossdock_update_item_tbl (i).ITEM_number
                     AND APS.SEGMENT1 =
                            l_crossdock_update_item_tbl (i).VENDOR_NUMBER
                     AND ASITE.VENDOR_SITE_CODE =
                            l_crossdock_update_item_tbl (i).VENDOR_SITE_CODE
            GROUP BY POH.SEGMENT1,
                     OOD.ORGANIZATION_CODE,
                     HL.LOCATION_CODE,
                     APS.VENDOR_NAME,
                     APS.SEGMENT1,
                     ASITE.VENDOR_SITE_CODE,
                     POL.ITEM_ID,
                     msib.segment1,
                     POLL.SHIP_TO_ORGANIZATION_ID,
                     POLL.RECEIVING_ROUTING_ID,
                     rrh.routing_name,
                     POLL.ATTRIBUTE1,
                     POLL.CLOSED_CODE;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         -- l_count := l_count + 1;

         IF L_COUNT = 0
         THEN
            DBMS_OUTPUT.PUT_LINE ('PLEASE UPDATE TO DISABLE THE FLEX RECORD');
         
         DBMS_OUTPUT.PUT_LINE ('**************************');
         DBMS_OUTPUT.put_line ('Update block Started');
         DBMS_OUTPUT.put_line ('Below Parameters Details');
         DBMS_OUTPUT.put_line ('l_count--' || l_count);
         DBMS_OUTPUT.put_line (
               l_crossdock_update_item_tbl (i).ORGANIZATION_CODE
            || '- '
            || l_crossdock_update_item_tbl (i).LOCATION_CODE
            || '-'
            || l_crossdock_update_item_tbl (i).ITEM_number
            || '- '
            || l_crossdock_update_item_tbl (i).VENDOR_NUMBER
            || '- '
            || l_crossdock_update_item_tbl (i).VENDOR_SITE_CODE
            || '- '
            || l_crossdock_update_item_tbl (i).SUPPLIER_NUMBER_SITE);
         DBMS_OUTPUT.PUT_LINE ('**************************');


         DBMS_OUTPUT.PUT_LINE ('Number of rows fetched' || J);
         END IF;

      END LOOP;
   END IF;
END;