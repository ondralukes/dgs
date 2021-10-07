<template>
  <div>
    <h1>{{$globalState.user.name}}</h1>
    <h2>Classes</h2>
    <div class="classes" v-if="classes !== null">
      <table v-for="c in classes" :key="c.id">
        <tr>
          <td colspan="3">
            <h3>{{c.name}}</h3>
          </td>
        </tr>
        <tr v-for="(g, index) in c.grades" :key="index">
          <td>{{g.timestamp.toLocaleString()}}</td>
          <td>{{g.name}}</td>
          <td>{{g.value}}</td>
        </tr>
        <tr>
          <td colspan="3">
            <b>
              {{c.grades.length}} grades total. Average: {{c.average.toFixed(3)}}
            </b>
          </td>
        </tr>
      </table>
    </div>
  </div>
</template>

<script>
export default {
  name: "User",
  data(){
    return{
      classes: null
    }
  },
  async created() {
    if(!this.$globalState.logged) this.$router.go(-1);
    const classIds = await this.$globalState.getClassesId();
    const classes = classIds.map(x => {return {id: x}});
    const promises = [];
    classes.forEach(c => {
      promises.push(new Promise(resolve => {
            this.$globalState.getClassName(c.id).then(name => {
              c.name = name;
              resolve();
            })
      }));
      promises.push(new Promise(resolve => {
        this.$globalState.getClassGrades(c.id).then(grades => {
          c.grades = grades.map(
              raw => {
                return {
                  name: raw[0],
                  timestamp: new Date(raw[1]),
                  value: raw[2]
                }
              }
          );
          c.average = c.grades.reduce((sum, x) => sum+x.value, 0) / c.grades.length;
          resolve();
        })
      }));
    });
    await Promise.all(promises);
    this.classes = classes;
  }
}
</script>

<style scoped>
table{
  margin: auto auto 10pt;
  width: 100%;
  border-collapse: collapse;
}
table, td{
  border: 2px solid;
}
td{
  width: 33%;
}
.classes{
  margin: auto;
  width: 100%;
  max-width: 700px;
}
</style>
